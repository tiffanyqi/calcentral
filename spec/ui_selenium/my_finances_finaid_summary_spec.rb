describe 'My Finances Financial Aid summary card', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      @driver = WebDriverUtils.launch_browser
      test_users = UserUtils.load_test_users
      testable_users = []
      test_output_heading = ['UID', 'FinAid Years', 'T & C Tested?', 'Title IV Tested?', 'COA', 'Grants', 'Fee Waivers', 'Work Study', 'Loans']
      test_output = UserUtils.initialize_output_csv(self, test_output_heading)
      links_tested = false

      @api_aid_years = ApiCSAidYearsPage.new @driver
      @api_fin_aid_data = ApiCSFinAidDataPage.new @driver
      @api_funding_sources = ApiCSFinAidFundingSourcesPage.new @driver
      @status_api = ApiMyStatusPage.new @driver

      @splash_page = CalCentralPages::SplashPage.new @driver
      @finances_page = CalCentralPages::MyFinancesPages::MyFinancesLandingPage.new @driver
      @fin_aid_page = CalCentralPages::MyFinancesPages::MyFinancesFinancialAidPage.new @driver

      test_users.each do |user|
        if user['finAidCs']
          uid = user['uid'].to_s
          logger.info "UID is #{uid}"

          aid_years = []
          api_semesters = []
          t_and_c_tested = false
          title_iv_tested = false
          api_cost_of_attend = nil
          api_grants_amt = nil
          api_waivers_amt = nil
          api_work_study_amt = nil
          api_loans_amt = nil

          begin
            @splash_page.load_page
            @splash_page.basic_auth uid
            @api_aid_years.get_json @driver
            @status_api.get_json @driver

            unless @api_aid_years.feed.nil? || !@status_api.has_finances_tab?

              @finances_page.load_fin_aid_summary

              api_aid_years = @api_aid_years.fin_aid_years
              api_aid_years.each { |year| aid_years << year['id'] }

              if api_aid_years.any?
                testable_users << uid

                api_aid_years.each do |year|
                  year_name = @api_aid_years.fin_aid_year_name year
                  year_id = @api_aid_years.fin_aid_year_id year
                  @api_fin_aid_data.get_json(@driver, year_id)
                  @api_funding_sources.get_json(@driver, year_id)

                  # TERMS & CONDITIONS (required annually) and TITLE IV (required once)

                  if @api_aid_years.t_and_c_approval(year).nil? || !@api_aid_years.t_and_c_approval(year)

                    t_and_c_tested = true

                    @finances_page.load_fin_aid_summary
                    @finances_page.select_fin_aid_year(api_aid_years, year_id)

                    has_t_and_c_msg = @finances_page.finaid_summary_message.include? 'You have not reviewed and agreed to the Terms and Conditions of your financial aid'
                    it ("tells UID #{uid} to accept the terms and conditions") { expect(has_t_and_c_msg).to be true }

                    @finances_page.click_t_and_c_link @fin_aid_page
                    sees_t_and_c = @fin_aid_page.t_and_c_body.include? 'I agree to the following'
                    it ("shows the Terms and Conditions to UID #{uid}") { expect(sees_t_and_c).to be true }

                    # Decline T&C
                    @fin_aid_page.decline_t_and_c
                    has_declined_msg = @fin_aid_page.declined_t_and_c_msg_element.visible?
                    it ("allows UID #{uid} to decline the terms and conditions") { expect(has_declined_msg).to be true }

                    # Accept T&C
                    @fin_aid_page.go_back_to_finances
                    @finances_page.click_t_and_c_link @fin_aid_page
                    @fin_aid_page.accept_t_and_c

                    # Authorize Title IV if necessary
                    if @api_aid_years.title_iv_approval.nil?
                      @fin_aid_page.authorize_title_iv
                      title_iv_tested = true
                    end

                    @fin_aid_page.wait_for_fin_aid_semesters
                    package_visible = @fin_aid_page.net_cost_section_element.when_visible WebDriverUtils.page_load_timeout

                    it "allows UID #{uid} to accept the terms and conditions" do
                      expect(package_visible).to be_truthy
                    end

                    it "allows UID #{uid} to authorize Title IV after accepting the terms and conditions" do
                      expect(package_visible).to be_truthy
                    end

                  elsif @api_aid_years.title_iv_approval.nil?

                    title_iv_tested = true

                    @finances_page.load_fin_aid_summary
                    @finances_page.select_fin_aid_year(api_aid_years, year_id)

                    has_title_iv_msg = @finances_page.finaid_summary_message.include? 'You have not selected a Title IV Release option'
                    it ("tells UID #{uid} to respond to Title IV") { expect(has_title_iv_msg).to be true }

                    # Authorize Title IV
                    @finances_page.click_title_iv_link @fin_aid_page
                    @fin_aid_page.authorize_title_iv
                    @fin_aid_page.wait_for_fin_aid_semesters
                    package_visible = @fin_aid_page.net_cost_section_element.visible?

                    it "allows UID #{uid} to authorize Title IV after accepting the terms and conditions" do
                      expect(package_visible).to be true
                    end

                  end

                  # SUMMARY CARD - check contents on both the landing page and the financial aid page

                  finances_pages = [@finances_page, @fin_aid_page]
                  finances_pages.each do |page|

                    page.load_fin_aid_summary year_id
                    page.select_fin_aid_year(api_aid_years, year_id) if page.instance_of?(CalCentralPages::MyFinancesPages::MyFinancesLandingPage)

                    ui_semesters = page.finaid_semesters
                    api_semesters = @api_aid_years.fin_aid_ui_semesters year
                    it ("shows the right semesters for the right aid year for UID #{uid}") { expect(ui_semesters).to eql(api_semesters) }

                    # AID PACKAGE

                    unless @api_fin_aid_data.feed.nil?

                      # NET COST

                      # Cost of Attendance
                      api_cost_of_attend = @api_fin_aid_data.budget_total
                      if api_cost_of_attend.nil?
                        has_coa = false
                        has_ui_coa = page.finaid_cost_of_attend?
                        it ("shows no Cost of Attendance for UID #{uid}") { expect(has_ui_coa).to be false }
                      else
                        page.net_cost_section_element.when_visible WebDriverUtils.page_event_timeout
                        ui_cost_of_attend = WebDriverUtils.currency_to_f page.finaid_cost_of_attend
                        it ("shows the right Cost of Attendance total for UID #{uid}") { expect(ui_cost_of_attend).to eql(api_cost_of_attend) }
                      end

                      # Gift Aid
                      api_gift_aid = @api_funding_sources.gift_aid_amt
                      if api_gift_aid.nil?
                        has_gift_aid = false
                        has_ui_gift_aid = page.finaid_gift_aid?
                        it ("shows no Gift Aid for UID #{uid}") { expect(has_ui_gift_aid).to be false }
                      else
                        has_gift_aid = true
                        ui_gift_aid = WebDriverUtils.currency_to_f page.finaid_gift_aid
                        it ("shows the right Gift Aid total for UID #{uid}") { expect(ui_gift_aid).to eql(api_gift_aid) }
                      end

                      # Net Cost - don't show if net cost is 0.00
                      if @api_fin_aid_data.net_cost_ttl.nil? || @api_fin_aid_data.net_cost_amt.nil?
                        has_ui_net_cost = page.finaid_net_cost?
                        it ("shows no Net Cost to UID #{uid}") { expect(has_ui_net_cost).to be false }
                      else
                        api_net_cost = @api_fin_aid_data.net_cost_amt
                        ui_net_cost = WebDriverUtils.currency_to_f page.finaid_net_cost
                        it ("shows the right Net Cost for UID #{uid}") { expect(ui_net_cost).to eql(api_net_cost) }
                      end

                      # FUNDING OFFERED

                      api_funding_offered_ttl = @api_fin_aid_data.funding_offered_amt
                      if api_funding_offered_ttl.nil?
                        has_ui_funding_offered_ttl = page.finaid_funding_offered_ttl?
                        it ("shows no Funding Offered total to UID #{uid}") { expect(has_ui_funding_offered_ttl).to be false }
                      else
                        ui_funding_offered_ttl = WebDriverUtils.currency_to_f page.finaid_funding_offered_ttl
                        it ("shows the right Funding Offered total for UID #{uid}") { expect(ui_funding_offered_ttl).to eql(api_funding_offered_ttl) }
                      end

                      api_gift_aid_funding = @api_fin_aid_data.funding_category_amt 'Gift Aid'
                      api_other_funding = @api_fin_aid_data.funding_category_amt 'Other Funding'

                      unless api_funding_offered_ttl.nil?

                        # Gift Aid

                        ui_gift_aid_offered = WebDriverUtils.currency_to_f page.finaid_funding_gift_aid
                        if api_gift_aid_funding.nil?
                          it ("shows zero Gift Aid offered for UID #{uid}") { expect(ui_gift_aid_offered).to be_zero }
                        else
                          it ("shows the right Gift Aid offered amount for UID #{uid}") { expect(ui_gift_aid_offered).to eql(api_gift_aid_funding) }

                          # Gift aid breakdown
                          api_gift_aid_items = @api_fin_aid_data.funding_category_items 'Gift Aid'

                          # Grants
                          api_grants = @api_fin_aid_data.funding_category_item(api_gift_aid_items, 'Grants and Scholarships')
                          api_grants_amt = @api_fin_aid_data.funding_category_item_amt api_grants
                          if api_grants_amt.nil?
                            ui_shows_grants = page.finaid_funding_grants?
                            it ("shows no Grants and Scholarships amount for UID #{uid}") { expect(ui_shows_grants).to be false }
                          else
                            ui_grants =WebDriverUtils.currency_to_f page.finaid_funding_grants
                            it ("shows the right Grants and Scholarships amount for UID #{uid}") { expect(ui_grants).to eql(api_grants_amt) }
                          end

                          # Fee waivers
                          api_waivers = @api_fin_aid_data.funding_category_item(api_gift_aid_items, 'Fee Waivers')
                          api_waivers_amt = @api_fin_aid_data.funding_category_item_amt api_waivers
                          if api_waivers_amt.nil?
                            ui_shows_waivers = page.finaid_funding_waivers?
                            it ("shows no Fee Waivers amount for UID #{uid}") { expect(ui_shows_waivers).to be false }
                          else
                            ui_waivers = WebDriverUtils.currency_to_f page.finaid_funding_waivers
                            it ("shows the right Fee Waivers for UID #{uid}") { expect(ui_waivers).to eql(api_waivers_amt) }
                          end

                        end

                        # Other Funding

                        ui_other_funding_ttl = WebDriverUtils.currency_to_f page.finaid_funding_other
                        if api_other_funding.nil?
                          it ("shows zero Other Funding for UID #{uid}") { expect(ui_other_funding_ttl).to be_zero }
                        else
                          it ("shows the right Other Funding total for UID #{uid}") { expect(ui_other_funding_ttl).to eql(api_other_funding) }

                          # Other funding breakdown
                          api_other_funding_items = @api_fin_aid_data.funding_category_items 'Other Funding'

                          # Work Study
                          api_work_study = @api_fin_aid_data.funding_category_item(api_other_funding_items, 'Work Study')
                          api_work_study_amt = @api_fin_aid_data.funding_category_item_amt api_work_study
                          if api_work_study_amt.nil?
                            has_work_study = false
                            ui_shows_work_study = page.finaid_funding_work_study?
                            it ("shows no Work Study amount for UID #{uid}") { expect(ui_shows_work_study).to be false }
                          else
                            has_work_study = true
                            ui_work_study = WebDriverUtils.currency_to_f page.finaid_funding_work_study
                            it ("shows the right Work Study for UID #{uid}") { expect(ui_work_study).to eql (api_work_study_amt) }
                          end

                          # Loans
                          api_loans = @api_fin_aid_data.funding_category_item(api_other_funding_items, 'Loans')
                          api_loans_amt = @api_fin_aid_data.funding_category_item_amt api_loans
                          if api_loans_amt.nil?
                            has_loans = false
                            ui_shows_loans = page.finaid_funding_loans?
                            it ("shows no Loans amount for UID #{uid}") { expect(ui_shows_loans).to be false }
                          else
                            has_loans = true
                            ui_loans = WebDriverUtils.currency_to_f page.finaid_funding_loans
                            it ("shows the right Loans total for UID #{uid}") { expect(ui_loans).to eql(api_loans_amt) }
                          end

                        end
                      end

                    end

                    has_details_link = page.finaid_details_link?
                    has_awards_link = page.awards_link?
                    has_shopping_sheet_link = page.shopping_sheet_link?

                    api_shopping_sheet_url = @api_fin_aid_data.shopping_sheet_url

                    if page.instance_of?(CalCentralPages::MyFinancesPages::MyFinancesLandingPage)

                      it ("offers a 'Details' link to UID #{uid}") { expect(has_details_link).to be true }

                      details_url = page.finaid_details_link_element.attribute('href')
                      it ("offers a 'Details' link pointing to the right aid year to UID #{uid}") { expect(details_url).to eql("#{WebDriverUtils.base_url}/finances/finaid/#{year_id}") }

                      if api_shopping_sheet_url.nil?
                        awards_url = page.awards_link_element.attribute('href')
                        it ("offers an 'Awards' link pointing to the right aid year to UID #{uid}") { expect(awards_url).to eql("#{WebDriverUtils.base_url}/finances/finaid/#{year_id}") }
                      else
                        it ("offers a 'Shopping Sheet' to UID #{uid}") { expect(has_shopping_sheet_link).to be true }
                      end

                    elsif page.instance_of?(CalCentralPages::MyFinancesPages::MyFinancesFinancialAidPage)

                      it ("offers no 'Details' link to UID #{uid}") { expect(has_details_link).to be false }
                      it ("offers no 'Awards' link to UID #{uid}") { expect(has_awards_link).to be false }

                      if api_shopping_sheet_url.nil?
                        it ("offers no 'Shopping Sheet' link to UID #{uid}") { expect(has_shopping_sheet_link).to be false }
                      else
                        it ("offers a 'Shopping Sheet' link to UID #{uid}") { expect(has_shopping_sheet_link).to be true }
                      end

                    end
                  end
                end

              else

                has_no_finaid_msg = @finances_page.no_finaid_message?
                it ("shows a 'No Fin Aid' message to UID #{uid}") { expect(has_no_finaid_msg).to be true }

                has_details_link = @finances_page.finaid_details_link?
                it ("offers no 'Details' link to UID #{uid}") { expect(has_details_link).to be false }

                # Links - only test external link for one of the test users

                unless links_tested
                  has_myfinaid_link = WebDriverUtils.verify_external_link(@driver, @finances_page.faso_link_element, 'Financial Aid and Scholarships | UC Berkeley')
                  it ("shows a link to MyFinAid to UID #{uid}") { expect(has_myfinaid_link).to be true }

                  has_csu_link = WebDriverUtils.verify_external_link(@driver, @finances_page.csu_link_element, 'Cal Student Central')
                  it ("shows a link to Cal Student Central to UID #{uid}") { expect(has_csu_link).to be true }

                  links_tested = true
                end

              end
            end

          rescue => e
            logger.error e.message + "\n" + e.backtrace.join("\n")

            # Force a test failure in the event of an error controlling the UI
            it ("caused an unexpected error in the test for UID #{uid}") { fail }

          ensure
            test_output_row = [uid, aid_years * ', ', t_and_c_tested, title_iv_tested, api_cost_of_attend, api_grants_amt,
                               api_waivers_amt, api_work_study_amt, api_loans_amt]
            UserUtils.add_csv_row(test_output, test_output_row)
          end
        end
      end
    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n ")
    ensure
      WebDriverUtils.quit_browser(@driver)
      it ('has FinAid data for at least one of the test users') { expect(testable_users.any?).to be true }
    end
  end
end
