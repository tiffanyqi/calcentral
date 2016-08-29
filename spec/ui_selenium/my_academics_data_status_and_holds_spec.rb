describe 'My Academics Status and Holds', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      driver = WebDriverUtils.launch_browser

      test_users = UserUtils.load_test_users.select { |user| user['status'] }
      test_output_heading = ['UID', 'Affiliations', 'Student', 'Ex-Student', 'Reg Statuses', 'Has Popover', 'Resident',
                             'Residency Message', 'Active Hold', 'Hold Reasons', 'Active Block']
      test_output = UserUtils.initialize_output_csv(self, test_output_heading)

      registered_users = []
      resident_users = []

      splash_page = CalCentralPages::SplashPage.new driver
      my_dashboard_page = CalCentralPages::MyDashboardPage.new driver
      my_academics_page = CalCentralPages::MyAcademicsStatusAndHoldsCard.new driver

      status_api_page = ApiMyStatusPage.new driver
      student_api_page = ApiEdosStudentPage.new driver
      registrations_api_page = ApiMyRegistrationsPage.new driver
      academics_api_page = ApiMyAcademicsPageSemesters.new driver
      holds_api_page = ApiCSHoldsPage.new driver

      test_users.each do |user|
        uid = user['uid']
        logger.info "UID is #{uid}"
        has_reg_status = nil
        term_statuses = []
        has_status_heading = nil
        api_res_status = nil
        api_residency_msg = nil
        has_hold = nil
        popover_hold_count = nil
        hold_reasons = []
        has_active_block = nil
        affiliations = []

        begin
          splash_page.load_page
          splash_page.basic_auth uid

          # Get user data from feeds

          # Status API
          status_api_page.get_json driver
          is_student = status_api_page.is_student?
          is_ex_student = status_api_page.is_ex_student?
          is_applicant = status_api_page.is_applicant?

          # Student API
          student_api_page.get_json driver
          affiliations = student_api_page.affiliation_types

          # Registrations API
          registrations_api_page.get_json driver
          if !registrations_api_page.current_term_reg_status && registrations_api_page.terms_with_registrations.length == 1
            has_reg_status = true
          end
          api_term_name = registrations_api_page.term_name registrations_api_page.current_term

          # Academics API
          academics_api_page.get_json driver

          # Holds API
          holds_api_page.get_json driver
          has_hold = holds_api_page.holds.any? unless holds_api_page.holds.nil?

          # Check contents of profile popover
          my_academics_page.load_page
          my_academics_page.open_profile_popover
          has_status_heading = WebDriverUtils.verify_block { my_academics_page.status_popover_heading_element.when_visible 10 }
          has_reg_alert = my_academics_page.reg_status_alert?
          has_hold_alert = my_academics_page.hold_status_alert?
          popover_hold_count = my_academics_page.hold_status_alert_number if has_hold_alert
          has_block_alert = my_academics_page.block_status_alert?

          # Students and new admits could have status info
          if is_student || is_applicant

            # New admits with no reg status info and no holds should have no status in the popover
            (is_applicant && !is_student && !has_reg_status && !has_hold) ?
                (it ("is not available via a person icon in the header for UID #{uid}") { expect(has_status_heading).to be false }) :
                (it ("is available via a person icon in the header for UID #{uid}") { expect(has_status_heading).to be true })

            my_academics_page.page_heading_element.when_visible timeout=WebDriverUtils.page_load_timeout
            has_status_card = my_academics_page.status_holds_section?

            it("appears on the Status and Holds card for UID #{uid}") { expect(has_status_card).to be true }

            # REGISTRATION STATUS

            my_acad_reg_statuses = my_academics_page.reg_status_elements
            has_ui_reg_statuses = WebDriverUtils.verify_block { my_academics_page.wait_until(10) { my_acad_reg_statuses.any? } }

            registrations_api_page.active_reg_status_terms.each do |term|

              api_term_name = registrations_api_page.term_name term
              api_term_registrations = registrations_api_page.term_registrations registrations_api_page.term_id(term)

              if api_term_registrations.present? && has_ui_reg_statuses
                logger.debug "Checking registration status for #{api_term_name}"
                logger.debug "There are #{api_term_registrations.length} registration statuses"

                # For now, only look for a single registration status per term
                api_reg_status = registrations_api_page.registered?(term, 0)
                term_statuses << "#{api_term_name} - #{api_reg_status}"

                if api_reg_status && has_ui_reg_statuses

                  my_acad_reg_status_summary = my_academics_page.reg_status_summary_element(api_term_name, 0).text
                  my_academics_page.reg_status_collapsed_element(api_term_name, 0).click
                  my_acad_reg_status_explanation = my_academics_page.reg_status_detail_element(api_term_name, 0).text

                  it ("shows 'Registered' for UID #{uid} in #{api_term_name}") { expect(my_acad_reg_status_summary).to eql('Officially Registered') }
                  it ("shows a you-are-registered explanation for UID #{uid} in #{api_term_name}") { expect(my_acad_reg_status_explanation).to include('You are officially registered') }

                  if term == registrations_api_page.current_term
                    registered_users << uid
                    it ("does not show a popover registration alert for UID #{uid} in #{api_term_name}") { expect(has_reg_alert).to be false }
                  end

                else

                  unless academics_api_page.careers.nil? || registrations_api_page.reg_status(registrations_api_page.term_id(term), 0).nil?

                    my_acad_reg_status_summary = my_academics_page.reg_status_summary_element(api_term_name, 0).text
                    my_academics_page.reg_status_collapsed_element(api_term_name, 0).click
                    my_acad_reg_status_explanation = my_academics_page.reg_status_detail_element(api_term_name, 0).text

                    it ("shows 'Not Registered' status during the regular term for UID #{uid} in #{api_term_name}") { expect(my_acad_reg_status_summary).to eql('Not Officially Registered') }

                    if api_term_name.include?('Summer')
                      it ("shows a you-are-not-registered explanation during the summary term for UID #{uid} in #{api_term_name}") { expect(my_acad_reg_status_explanation).to include('You are not officially registered for this term.') }
                    else
                      it ("shows a you-are-not-registered explanation during the regular term for UID #{uid} in #{api_term_name}") { expect(my_acad_reg_status_explanation).to include('You may have limited access to campus services until you are officially registered.') }
                    end

                    if term == registrations_api_page.current_term && !api_term_name.include?('Summer')

                      it ("shows a registration alert on the popover during the regular term for UID #{uid} in #{api_term_name}") { expect(has_reg_alert).to be true }

                      if has_reg_alert
                        reg_alert_text = my_academics_page.reg_status_alert
                        it ("shows a registration alert message on the popover during the regular term for UID #{uid} in #{api_term_name}") { expect(reg_alert_text).to include('Not Registered') }
                      end

                    else
                      it ("does not show a profile popover registration alert during term transition for UID #{uid} in #{api_term_name}") { expect(has_reg_alert).to be false }
                    end

                  end
                end
              end

            end

            # CALIFORNIA RESIDENCY

            # Residency info can take a while to load, so wait a few seconds to see whether or not it appears
            has_res_status = WebDriverUtils.verify_block { my_academics_page.res_status_summary_element(0).when_present 5 }
            has_res_status_explanation = WebDriverUtils.verify_block { my_academics_page.show_res_status_detail 0 }

            if has_ui_reg_statuses && student_api_page.has_residency?

              it ("shows residency status for UID #{uid}") do
                expect(has_res_status).to be true
                expect(has_res_status_explanation).to be true
              end

              api_res_status = student_api_page.residency_desc
              api_res_from_term = student_api_page.residency_from_term

              resident_users << uid if api_res_status == 'Resident'

              my_acad_res_status = my_academics_page.res_status_summary_element(0).text
              my_acad_res_from_term = my_academics_page.res_from_term_element(0).text
              shows_slr_submission_link = my_academics_page.res_slr_link_element(0).present?

              it ("shows residency status of '#{api_res_status}' for UID #{uid}") { expect(my_acad_res_status).to eql(api_res_status) }
              it ("shows a residency term applied for UID #{uid}") { expect(my_acad_res_from_term).to eql(api_res_from_term) }
              it ("shows an SLR link for UID #{uid}") { expect(shows_slr_submission_link).to be true }

              has_green_res_status_icon = my_academics_page.res_status_icon_green_element(0).present?
              has_gold_res_status_icon = my_academics_page.res_status_icon_gold_element(0).present?
              has_red_res_status_icon = my_academics_page.res_status_icon_red_element(0).present?

              if %w(Resident Non-Resident).include? api_res_status
                it ("shows a green residency status icon for UID #{uid}") { expect(has_green_res_status_icon).to be true }
              elsif api_res_status == 'Pending'
                it ("shows a gold residency status icon for UID #{uid}") { expect(has_gold_res_status_icon).to be true }
              else
                it ("shows a red residency status icon for UID #{uid}") { expect(has_red_res_status_icon).to be true }
              end

            else

              it ("shows no residency status for UID #{uid}") { expect(has_res_status).to be false }

            end

            # HOLDS

            if has_hold

              # Holds on profile popover
              holds_api_hold_count = holds_api_page.holds.length.to_s
              my_acad_hold_count = my_academics_page.active_hold_count.to_s

              it ("shows a hold alert on the popover for UID #{uid}") { expect(has_hold_alert).to be true }
              it ("shows the number of holds on the profile popover for UID #{uid}") { expect(popover_hold_count).to eql(holds_api_hold_count) }
              it ("shows the number of holds on My Academics for UID #{uid}") { expect(my_acad_hold_count).to eql(holds_api_hold_count) }

              # Holds on Academics page
              hold_reasons = my_academics_page.active_hold_reasons
              hold_dates = my_academics_page.active_hold_dates

              holds_api_hold_reasons = holds_api_page.hold_reasons
              holds_api_hold_dates = holds_api_page.hold_dates

              it ("shows the hold reason on the academics page for UID #{uid}") { expect(hold_reasons).to eql(holds_api_hold_reasons) }
              it ("shows the hold date on the academics page for UID #{uid}") { expect(hold_dates).to eql(holds_api_hold_dates) }

            elsif is_applicant && !is_student

              has_holds_heading = my_academics_page.active_holds_heading?

              it ("has no holds section for UID #{uid}") { expect(has_holds_heading).to be false }

            else

              has_no_holds_message = WebDriverUtils.verify_block { my_academics_page.no_active_holds_message_element.when_visible }

              it ("shows no hold alert on the profile popover for UID #{uid}") { expect(has_hold_alert).to be false }
              it ("shows a no active hold message for UID #{uid}") { expect(has_no_holds_message).to be true }

            end

            # BLOCKS

            has_blocks_heading = my_academics_page.active_blocks_heading?
            has_show_block_history_button = my_academics_page.show_block_history_button?

            it ("has no blocks section for UID #{uid}") { expect(has_blocks_heading).to be false }
            it ("shows no show-block-history button for UID #{uid}") { expect(has_show_block_history_button).to be false }
            it ("shows no popover block alert for UID #{uid}") { expect(has_block_alert).to be false }

            # PROFILE POPOVER ALERT LINKS

            if has_reg_alert
              my_dashboard_page.load_page
              my_dashboard_page.open_profile_popover
              my_dashboard_page.click_reg_status_alert
              reg_status_link_works = my_academics_page.status_table_element.when_visible timeout

              it ("offers a link from the profile popover registration alert to My Academics for UID #{uid}") { expect(reg_status_link_works).to be_truthy }
            end

            if has_hold_alert
              my_dashboard_page.load_page
              my_dashboard_page.open_profile_popover
              my_dashboard_page.click_hold_status_alert
              hold_alert_link_works = my_academics_page.active_holds_table_element.when_visible timeout

              it ("offers a link from the profile popover active hold alert to My Academics for UID #{uid}") { expect(hold_alert_link_works).to be_truthy }
            end

          elsif is_ex_student && has_reg_status && !status_api_page.is_faculty?

            it ("is available via a person icon in the header for UID #{uid}") { expect(has_status_heading).to be true }
            it ("shows no hold alert on the popover for UID #{uid}") { expect(has_hold_alert).to be false }
            it ("shows no block alert on the popover for UID #{uid}") { expect(has_block_alert).to be false }
            it ("shows no registration alert on the popover for UID #{uid}") { expect(has_reg_alert).to be false }

          else

            it ("is not available via a person icon in the header for UID #{uid}") { expect(has_status_heading).to be false }

          end

        rescue => e
          logger.error "#{e.message + "\n"} #{e.backtrace.join("\n ")}"
        ensure
          test_output_row = [uid, affiliations * ', ', is_student, is_ex_student, term_statuses * ', ', has_status_heading,
                             api_res_status, api_residency_msg, has_hold, hold_reasons * ', ', has_active_block]
          UserUtils.add_csv_row(test_output, test_output_row)
        end
      end

      it ('shows "Registered" in the current term for at least one of the test UIDs') { expect(registered_users.any?).to be true }
      it ('shows "Resident" for at least one of the test UIDs') { expect(resident_users.any?).to be true }

    rescue => e
      logger.error "#{e.message + "\n"} #{e.backtrace.join("\n ")}"
    ensure
      WebDriverUtils.quit_browser driver
    end
  end
end
