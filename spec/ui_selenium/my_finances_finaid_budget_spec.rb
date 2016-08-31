describe 'My Finances Financial Aid Estimated Cost of Attendance card', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      @driver = WebDriverUtils.launch_browser
      test_users = UserUtils.load_test_users
      testable_users = []
      test_output_heading = ['UID', 'Aid Years', 'Standard Items', 'Standard Amounts', 'Additional Items', 'Additional Amounts']
      test_output = UserUtils.initialize_output_csv(self, test_output_heading)

      @api_aid_years = ApiCSAidYearsPage.new @driver
      @api_fin_aid_data = ApiCSFinAidDataPage.new @driver

      @splash_page = CalCentralPages::SplashPage.new @driver
      @finances_page = CalCentralPages::MyFinancesPages::MyFinancesLandingPage.new @driver
      @fin_aid_page = CalCentralPages::MyFinancesPages::MyFinancesFinancialAidPage.new @driver

      test_users.each do |user|
        if user['finAidCs']
          uid = user['uid']
          logger.info "UID is #{uid}"
          aid_years = []
          api_std_items = []
          api_std_amts = []
          api_addl_items = []
          api_addl_amts = []

          begin
            @splash_page.load_page
            @splash_page.basic_auth uid
            @api_aid_years.get_json @driver

            unless @api_aid_years.feed.nil?

              api_aid_years = @api_aid_years.fin_aid_years
              api_aid_years.each { |year| aid_years << year['id'] }

              if api_aid_years.any?
                api_aid_years.each do |year|

                  year_id = @api_aid_years.fin_aid_year_id year

                  @api_fin_aid_data.get_json(@driver, year_id)

                  # Don't bother executing tests if the package is not yet visible
                  unless @api_aid_years.t_and_c_approval(year).nil? || !@api_aid_years.t_and_c_approval(year)
                    @fin_aid_page.load_fin_aid_budget year_id

                    # ANNUAL VIEW

                    annual_data = @api_fin_aid_data.budget_annual_data
                    std_budget_items = @api_fin_aid_data.budget_items(annual_data, 'Standard Budget Items')
                    addl_budget_items = @api_fin_aid_data.budget_items(annual_data, 'Additional Budget Items')

                    # Standard Budget Items

                    if std_budget_items.any?
                      testable_users << uid

                      std_budget_table = @fin_aid_page.standard_budget_table_element

                      ui_std_items = @fin_aid_page.budget_items std_budget_table
                      ui_std_amts = @fin_aid_page.budget_item_annual_totals std_budget_table

                      api_std_items = @api_fin_aid_data.budget_item_titles(annual_data, 'Standard Budget Items')
                      api_std_amts = @api_fin_aid_data.budget_item_totals(annual_data, 'Standard Budget Items')

                      it ("shows the standard budget items for UID #{uid}") { expect(ui_std_items).to eql(api_std_items) }
                      it ("shows the standard budget item amounts for UID #{uid}") { expect(ui_std_amts).to eql(api_std_amts) }

                      # Standard Budget Sub-items

                      std_budget_item_toggles = @fin_aid_page.standard_budget_row_toggle_elements
                      std_budget_items.each do |item|

                        @fin_aid_page.expand_budget_item(std_budget_item_toggles, std_budget_items.index(item))

                        ui_std_subitems = @fin_aid_page.budget_subitems
                        ui_std_subitem_amts = @fin_aid_page.budget_subitem_annual_amounts

                        api_std_subitems = @api_fin_aid_data.budget_sub_item_titles item
                        api_std_subitem_amts = @api_fin_aid_data.budget_sub_item_totals item

                        it ("shows the standard budget sub-items for UID #{uid}") { expect(ui_std_subitems).to eql(api_std_subitems) }
                        it ("shows the standard budget sub-item amounts for UID #{uid}") { expect(ui_std_subitem_amts).to eql(api_std_subitem_amts) }

                      end
                    end

                    # Additional Budget Items

                    if addl_budget_items.any?

                      addl_budget_table = @fin_aid_page.additional_budget_table_element

                      ui_addl_items = @fin_aid_page.budget_items addl_budget_table
                      ui_addl_amts = @fin_aid_page.budget_item_annual_totals addl_budget_table

                      api_addl_items = @api_fin_aid_data.budget_item_titles(annual_data, 'Additional Budget Items')
                      api_addl_amts = @api_fin_aid_data.budget_item_totals(annual_data, 'Additional Budget Items')

                      it ("shows the additional budget items for UID #{uid}") { expect(ui_addl_items).to eql(api_addl_items) }
                      it ("shows the additional budget item amounts for UID #{uid}") { expect(ui_addl_amts).to eql(api_addl_amts) }

                      # Additional Budget Sub-items

                      addl_budget_item_toggles = @fin_aid_page.additional_budget_row_toggle_elements
                      addl_budget_items.each do |item|

                        @fin_aid_page.expand_budget_item(addl_budget_item_toggles, addl_budget_items.index(item))

                        ui_addl_subitems = @fin_aid_page.budget_subitems
                        ui_addl_subitem_amts = @fin_aid_page.budget_subitem_annual_amounts

                        api_addl_subitems = @api_fin_aid_data.budget_sub_item_titles item
                        api_addl_subitem_amts = @api_fin_aid_data.budget_sub_item_totals item

                        it ("shows the additional budget sub-items for UID #{uid}") { expect(ui_addl_subitems).to eql(api_addl_subitems) }
                        it ("shows the additional budget sub-item amounts for UID #{uid}") { expect(ui_addl_subitem_amts).to eql(api_addl_subitem_amts) }

                      end
                    end

                    # TERM VIEW

                    term_data = @api_fin_aid_data.budget_term_data
                    std_budget_term_items = @api_fin_aid_data.budget_items(term_data, 'Standard Budget Items')
                    addl_budget_term_items = @api_fin_aid_data.budget_items(term_data, 'Additional Budget Items')

                    @fin_aid_page.toggle_budget_view

                    # Standard Budget Items

                    if std_budget_term_items.any?

                      std_budget_table = @fin_aid_page.standard_budget_table_element

                      ui_std_term_items = @fin_aid_page.budget_items std_budget_table
                      ui_std_term_amts = @fin_aid_page.budget_item_term_amounts std_budget_table
                      ui_std_term_ttls = @fin_aid_page.budget_item_term_totals std_budget_table

                      api_std_term_items = @api_fin_aid_data.budget_item_titles(term_data, 'Standard Budget Items')
                      api_std_term_amts = @api_fin_aid_data.budget_item_amounts(term_data, 'Standard Budget Items')
                      api_std_term_ttls = @api_fin_aid_data.budget_item_totals(term_data, 'Standard Budget Items')

                      it ("shows the standard budget items by term for UID #{uid}") { expect(ui_std_term_items).to eql(api_std_term_items) }
                      it ("shows the standard budget item amounts by term for UID #{uid}") { expect(ui_std_term_amts).to eql(api_std_term_amts) }
                      it ("shows the standard budget item totals by term for UID #{uid}") { expect(ui_std_term_ttls).to eql(api_std_term_ttls) }

                      # Standard Budget Sub-items

                      std_budget_item_toggles = @fin_aid_page.standard_budget_row_toggle_elements
                      std_budget_term_items.each do |item|

                        @fin_aid_page.expand_budget_item(std_budget_item_toggles, std_budget_term_items.index(item))

                        ui_std_term_subitems = @fin_aid_page.budget_subitems
                        ui_std_term_subitem_amts = @fin_aid_page.budget_subitem_term_amounts
                        ui_std_term_subitem_ttls = @fin_aid_page.budget_subitem_term_totals

                        api_std_term_subitems = @api_fin_aid_data.budget_sub_item_titles item
                        api_std_term_subitem_amts = @api_fin_aid_data.budget_sub_item_amounts item
                        api_std_term_subitem_ttls = @api_fin_aid_data.budget_sub_item_totals item

                        it ("shows the standard budget sub-items by term for UID #{uid}") { expect(ui_std_term_subitems).to eql(api_std_term_subitems) }
                        it ("shows the standard budget sub-item amounts by term for UID #{uid}") { expect(ui_std_term_subitem_amts).to eql(api_std_term_subitem_amts) }
                        it ("shows the standard budget sub-item totals by term for UID #{uid}") { expect(ui_std_term_subitem_ttls).to eql(api_std_term_subitem_ttls) }

                      end
                    end

                    # Additional Budget Items

                    if addl_budget_term_items.any?

                      addl_budget_table = @fin_aid_page.additional_budget_table_element

                      ui_addl_term_items = @fin_aid_page.budget_items addl_budget_table
                      ui_addl_term_amts = @fin_aid_page.budget_item_term_amounts addl_budget_table
                      ui_addl_term_ttls = @fin_aid_page.budget_item_term_totals addl_budget_table

                      api_addl_term_items = @api_fin_aid_data.budget_item_titles(term_data, 'Additional Budget Items')
                      api_addl_term_amts = @api_fin_aid_data.budget_item_amounts(term_data, 'Additional Budget Items')
                      api_addl_term_ttls = @api_fin_aid_data.budget_item_totals(term_data, 'Additional Budget Items')

                      it ("shows the additional budget items by term for UID #{uid}") { expect(ui_addl_term_items).to eql(api_addl_term_items) }
                      it ("shows the additional budget item amounts by term for UID #{uid}") { expect(ui_addl_term_amts).to eql(api_addl_term_amts) }
                      it ("shows the additional budget item totals by term for UID #{uid}") { expect(ui_addl_term_ttls).to eql(api_addl_term_ttls) }

                      # Additional Budget Sub-items

                      addl_budget_item_toggles = @fin_aid_page.additional_budget_row_toggle_elements
                      addl_budget_term_items.each do |item|

                        @fin_aid_page.expand_budget_item(addl_budget_item_toggles, addl_budget_term_items.index(item))

                        ui_addl_term_subitems = @fin_aid_page.budget_subitems
                        ui_addl_term_subitem_amts = @fin_aid_page.budget_subitem_term_amounts
                        ui_addl_term_subitem_ttls = @fin_aid_page.budget_subitem_term_totals

                        api_addl_term_subitems = @api_fin_aid_data.budget_sub_item_titles item
                        api_addl_term_subitem_amts = @api_fin_aid_data.budget_sub_item_amounts item
                        api_addl_term_subitem_ttls = @api_fin_aid_data.budget_sub_item_totals item

                        it ("shows the additional budget sub-items by term for UID #{uid}") { expect(ui_addl_term_subitems).to eql(api_addl_term_subitems) }
                        it ("shows the additional budget sub-item amounts by term for UID #{uid}") { expect(ui_addl_term_subitem_amts).to eql(api_addl_term_subitem_amts) }
                        it ("shows the additional budget sub-item totals by term for UID #{uid}") { expect(ui_addl_term_subitem_ttls).to eql(api_addl_term_subitem_ttls) }

                      end

                    else
                      # TODO: when test data available, verify 'you have no budget' scenario
                    end
                  end
                end
              end
            end

          rescue => e
            logger.error e.message + "\n" + e.backtrace.join("\n")

            # Force a test failure in the event of an error controlling the UI
            it ("caused an unexpected error in the test for UID #{uid}") { fail }

          ensure
            test_output_row = [uid, aid_years * ', ', api_std_items * "\r", api_std_amts * "\r", api_addl_items * "\r", api_addl_amts * "\r"]
            UserUtils.add_csv_row(test_output, test_output_row)
          end
        end
      end
    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n ")
    ensure
      WebDriverUtils.quit_browser(@driver)
      it ('has FinAid budget data for at least one of the test users') { expect(testable_users.any?).to be true }
    end
  end
end
