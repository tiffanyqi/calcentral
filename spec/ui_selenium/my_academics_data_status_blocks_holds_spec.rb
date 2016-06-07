describe 'My Academics Status, Blocks, and Holds', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      driver = WebDriverUtils.launch_browser

      test_users = UserUtils.load_test_users.select { |user| user['status'] }
      test_output_heading = ['UID', 'Affiliations', 'Student', 'Ex-Student', 'Registered', 'Reg Status', 'Reg Status Summary',
                             'Resident', 'Active Hold', 'Hold Reasons', 'Active Block', 'Block Types', 'Block History']
      test_output = UserUtils.initialize_output_csv(self, test_output_heading)

      registered_users = []
      resident_users = []
      non_res_link_tested = false
      pending_res_link_tested = false

      splash_page = CalCentralPages::SplashPage.new driver
      my_dashboard_page = CalCentralPages::MyDashboardPage.new driver
      my_academics_page = CalCentralPages::MyAcademicsStatusBlocksHoldsCard.new driver

      status_api_page = ApiMyStatusPage.new driver
      student_api_page = ApiEdosStudentPage.new driver
      academics_api_page = ApiMyAcademicsPageSemesters.new driver
      holds_api_page = ApiCSHoldsPage.new driver
      badges_api_page = ApiMyBadgesPage.new driver
      financials_api_page = ApiMyFinancialsPage.new driver
      profile_card = CalCentralPages::MyAcademicsProfileCard.new driver

      test_users.each do |user|
        uid = user['uid']
        logger.info "UID is #{uid}"
        api_reg_status = nil
        api_res_status = nil
        has_active_hold = nil
        popover_hold_count = nil
        hold_reasons = []
        has_active_block = nil
        popover_block_count = nil
        block_types = nil
        has_block_history = nil
        affiliations = []

        begin
          splash_page.load_page
          splash_page.basic_auth uid

          # Get user data from feeds
          status_api_page.get_json driver
          is_student = status_api_page.is_student?
          is_ex_student = status_api_page.is_ex_student?
          is_registered = status_api_page.is_registered?

          student_api_page.get_json driver
          affiliations = student_api_page.affiliation_types

          academics_api_page.get_json driver
          badges_api_page.get_json driver
          academics_api_page.transition_term? ?
              api_reg_status = academics_api_page.trans_term_registered? :
              api_reg_status = badges_api_page.is_registered?
          api_reg_status_summary = badges_api_page.reg_status_summary

          holds_api_page.get_json driver
          has_active_hold = holds_api_page.holds.any? unless holds_api_page.holds.nil?

          financials_api_page.get_json driver

          # Check contents of profile popover
          my_academics_page.load_page
          my_academics_page.open_profile_popover

          # Status info can take a while to load, so wait 10 seconds to see whether or not it appears
          has_status_heading = WebDriverUtils.verify_block { my_academics_page.status_popover_heading_element.when_visible 10 }
          has_reg_alert = my_academics_page.reg_status_alert?
          has_hold_alert = my_academics_page.hold_status_alert?
          popover_hold_count = my_academics_page.hold_status_alert_number if has_hold_alert
          has_block_alert = my_academics_page.block_status_alert?
          popover_block_count = my_academics_page.block_status_alert_number if has_block_alert

          # Students and new admits could have status info
          if is_student || (affiliations.include?('ADMT_UX'))

            # New admits with no reg status info and no holds should have no status in the popover
            if affiliations.include?('ADMT_UX') && badges_api_page.reg_status_summary.nil? && !has_active_hold
              it ("is not available via a person icon in the header for UID #{uid}") { expect(has_status_heading).to be false }
            else
              it ("is available via a person icon in the header for UID #{uid}") { expect(has_status_heading).to be true }
            end

            my_academics_page.page_heading_element.when_visible timeout=WebDriverUtils.page_load_timeout

            # REGISTRATION STATUS

            # Do not look for reg status if student has no reg status or if ex-student has no semester data
            unless (is_student && badges_api_page.reg_status_summary.nil?) || (is_ex_student && academics_api_page.all_student_semesters.empty?)

              api_reg_status_explanation = badges_api_page.reg_status_explanation
              has_reg_status_summary = my_academics_page.reg_status_summary?
              has_reg_status_explanation = my_academics_page.reg_status_explanation?

              if api_reg_status_summary.nil?
                it "shows no registration status summary or explanation for UID #{uid}" do
                  expect(has_reg_status_summary).to be false
                  expect(has_reg_status_explanation).to be false
                end
              else
                it "shows a registration status summary and explanation for UID #{uid}" do
                  expect(has_reg_status_summary).to be true
                  expect(has_reg_status_explanation).to be true
                end

                my_acad_reg_status_summary = my_academics_page.reg_status_summary
                my_acad_reg_status_explanation = my_academics_page.reg_status_explanation
                registered_users << uid if my_acad_reg_status_summary == 'Registered'

                # Currently registered users always see 'registered' messaging regardless of term
                if api_reg_status
                  it ("shows 'Registered' for UID #{uid}") { expect(my_acad_reg_status_summary).to eql('Registered') }
                  it ("shows a you-are-registered explanation for UID #{uid}") { expect(my_acad_reg_status_explanation).to include(api_reg_status_explanation) }
                  it ("does not show a popover registration alert for UID #{uid}") { expect(has_reg_alert).to be false }
                end

                # During term transitions (i.e., summer and winter break)
                has_term_transition_msg = profile_card.term_transition_msg?
                has_term_transition_msg ? term_transition_msg = profile_card.term_transition_msg : term_transition_msg = nil

                if academics_api_page.transition_term?
                  term_name = academics_api_page.trans_term_name

                  # No users will have reg status alert, regardless of reg status
                  it ("does not show a profile popover registration alert during term transition for UID #{uid}") { expect(has_reg_alert).to be false }

                  # Users registered during the transition term
                  if api_reg_status
                    if academics_api_page.trans_term_profile_current?
                      it ("shows no 'you are registered' message during term transition for UID #{uid}") { expect(has_term_transition_msg).to be false }
                    else
                      it ("shows a 'you are registered' message during term transition for UID #{uid}") { expect(term_transition_msg).to include("You are registered for the #{term_name} term") }
                    end

                  # Users not registered during the transition term
                  else
                    if academics_api_page.trans_term_profile_current?
                      it ("shows no 'you are not registered' message during term transition for UID #{uid}") { expect(has_term_transition_msg).to be false }
                      it ("shows 'Not Registered' status summary for UID #{uid}") { expect(my_acad_reg_status_summary).to eql("Not registered for #{term_name}") }

                    else
                      it ("shows a 'you are not registered' message during term transition for UID #{uid}") { expect(term_transition_msg).to include("You are not officially registered for the #{term_name} term") }
                    end
                  end

                # During regular terms (spring and fall)
                else
                  it ("shows no term transition message during the regular term for UID #{uid}") { expect(has_term_transition_msg).to be false }

                  # Users not registered during the regular term
                  unless api_reg_status

                    it ("shows a registration alert on the popover during the regular term for UID #{uid}") { expect(has_reg_alert).to be true }

                    if has_reg_alert

                      reg_alert_text = my_academics_page.reg_status_alert

                      it ("shows a registration alert message on the popover during the regular term for UID #{uid}") { expect(reg_alert_text).to include(api_reg_status_summary) }
                      it ("shows 'Not Registered' status during the regular term for UID #{uid}") { expect(my_acad_reg_status_summary).to eql(api_reg_status_summary) }
                      it ("shows a you-are-not-registered explanation during the regular term for UID #{uid}") { expect(my_acad_reg_status_explanation).to include(api_reg_status_explanation) }
                    end
                  end
                end
              end

              # CALIFORNIA RESIDENCY

              # Residency info can take a while to load
              has_res_status = WebDriverUtils.verify_block { my_academics_page.res_status_summary_element.when_present 5 }

              if has_reg_status_summary && student_api_page.has_residency? && !academics_api_page.colleges.include?('Haas School of Business')

                it ("shows residency status for UID #{uid}") { expect(has_res_status).to be true }

                api_res_status = student_api_page.residency_desc
                my_acad_res_status = my_academics_page.res_status_summary

                it ("shows residency status of '#{api_res_status}' for UID #{uid}") { expect(my_acad_res_status).to eql(api_res_status) }

                has_green_res_status_icon = my_academics_page.res_status_icon_green?
                has_gold_res_status_icon = my_academics_page.res_status_icon_gold?
                has_red_res_status_icon = my_academics_page.res_status_icon_red?

                shows_slr_submission_link = my_academics_page.res_slr_submit_link?
                shows_slr_status_link = my_academics_page.res_slr_status_link?

                # Check presence of links, but only verify that each link directs to the right page for one of the test users
                shows_res_info_link = if api_res_status == 'Resident'
                                        my_academics_page.res_info_link?
                                      elsif api_res_status == 'Non-Resident'
                                        if non_res_link_tested
                                          my_academics_page.res_info_link?
                                        else
                                          WebDriverUtils.verify_external_link(driver, my_academics_page.res_info_link_element, 'Tuition, Fees, & Residency | Office of the Registrar')
                                          non_res_link_tested = true
                                        end
                                      else
                                        if pending_res_link_tested
                                          my_academics_page.res_info_link?
                                        else
                                          WebDriverUtils.verify_external_link(driver, my_academics_page.res_info_link_element, 'How to Apply for Residency (for Tuition Purposes) | Office of the Registrar')
                                          pending_res_link_tested = true
                                        end
                                      end

                if api_res_status == 'Resident'

                  resident_users << uid

                  it ("shows a green residency status icon for UID #{uid}") { expect(has_green_res_status_icon).to be true }
                  it ("shows no SLR submission link for UID #{uid}") { expect(shows_slr_submission_link).to be false }
                  it ("shows no SLR status link for UID #{uid}") { expect(shows_slr_status_link).to be false }
                  it ("shows no residency info link for UID #{uid}") { expect(shows_res_info_link).to be false }

                elsif api_res_status == 'Non-Resident'

                  it ("shows a green residency status icon for UID #{uid}") { expect(has_green_res_status_icon).to be true }
                  it ("shows no SLR submission link for UID #{uid}") { expect(shows_slr_submission_link).to be false }
                  it ("shows no SLR status link for UID #{uid}") { expect(shows_slr_status_link).to be false }
                  it ("shows a 'residency info' link for UID #{uid}") { expect(shows_res_info_link).to be true }

                elsif api_res_status == 'Pending'

                  it ("shows a gold residency status icon for UID #{uid}") { expect(has_gold_res_status_icon).to be true }
                  it ("shows a SLR submission link for UID #{uid}") { expect(shows_slr_submission_link).to be false }
                  it ("shows a SLR status link for UID #{uid}") { expect(shows_slr_status_link).to be true }
                  it ("shows a 'residency info' link for UID #{uid}") { expect(shows_res_info_link).to be true }

                else

                  it ("shows a red residency status icon for UID #{uid}") { expect(has_red_res_status_icon).to be true }
                  it ("shows a SLR submission link for UID #{uid}") { expect(shows_slr_submission_link).to be true }
                  it ("shows no SLR status link for UID #{uid}") { expect(shows_slr_status_link).to be false }
                  it ("shows a 'residency info' link for UID #{uid}") { expect(shows_res_info_link).to be true }

                end

              else

                it ("shows no residency status for UID #{uid}") { expect(has_res_status).to be false }

              end
            end

            # HOLDS

            if has_active_hold

              # Active holds on profile popover
              holds_api_hold_count = holds_api_page.holds.length.to_s
              my_acad_hold_count = my_academics_page.active_hold_count.to_s

              it ("shows a hold alert on the popover for UID #{uid}") { expect(has_hold_alert).to be true }
              it ("shows the number of holds on the profile popover for UID #{uid}") { expect(popover_hold_count).to eql(holds_api_hold_count) }
              it ("shows the number of holds on My Academics for UID #{uid}") { expect(my_acad_hold_count).to eql(holds_api_hold_count) }

              # Active holds on Academics page
              hold_reasons = my_academics_page.active_hold_reasons
              hold_dates = my_academics_page.active_hold_dates

              holds_api_hold_reasons = holds_api_page.hold_reasons
              holds_api_hold_dates = holds_api_page.hold_dates

              it ("shows the hold reason on the academics page for UID #{uid}") { expect(hold_reasons).to eql(holds_api_hold_reasons) }
              it ("shows the hold date on the academics page for UID #{uid}") { expect(hold_dates).to eql(holds_api_hold_dates) }

            elsif (affiliations.include?('ADMT_UX') && !affiliations.include?('STUDENT')) || badges_api_page.reg_status.nil?

              has_holds_heading = my_academics_page.active_holds_heading?

              it ("has no holds section for UID #{uid}") { expect(has_holds_heading).to be false }

            else

              has_no_holds_message = my_academics_page.no_active_holds_message?

              it ("shows no hold alert on the profile popover for UID #{uid}") { expect(has_hold_alert).to be false }
              it ("shows a no active hold message for UID #{uid}") { expect(has_no_holds_message).to be true }

            end

            # ACTIVE BLOCKS

            has_active_block = academics_api_page.active_blocks.any? unless academics_api_page.active_blocks.nil?

            if has_active_block

              # Active blocks on profile popover
              academics_api_block_count = academics_api_page.active_blocks.length.to_s
              my_acad_block_count = my_academics_page.active_block_count.to_s

              it ("shows a block alert on the popover for UID #{uid}") { expect(has_block_alert).to be true }
              it ("shows the number of blocks on the profile popover for UID #{uid}") { expect(popover_block_count).to eql(academics_api_block_count) }
              it ("shows the number of blocks on My Academics for UID #{uid}") { expect(my_acad_block_count).to eql(academics_api_block_count) }

              # Active blocks on Academics page
              my_acad_block_types = my_academics_page.active_block_types
              my_acad_block_reasons = my_academics_page.active_block_reasons
              my_acad_block_offices = my_academics_page.active_block_offices
              my_acad_block_dates = my_academics_page.active_block_dates
              block_types = my_acad_block_reasons * ', '

              academics_api_block_types = academics_api_page.active_block_types
              academics_api_block_reasons = academics_api_page.active_block_reasons
              academics_api_block_offices = academics_api_page.active_block_offices
              academics_api_block_dates = academics_api_page.active_block_dates

              it ("shows the block type on the academics page for UID #{uid}") { expect(my_acad_block_types).to eql(academics_api_block_types) }
              it ("shows the block reason on the academics page for UID #{uid}") { expect(my_acad_block_reasons).to eql(academics_api_block_reasons) }
              it ("shows the block office on the academics page for UID #{uid}") { expect(my_acad_block_offices).to eql(academics_api_block_offices) }
              it ("shows the block date on the academics page for UID #{uid}") { expect(my_acad_block_dates).to eql(academics_api_block_dates) }

            # If user has no reg status but has a hold, the blocks messaging still appears
            elsif (has_active_hold && badges_api_page.reg_status.nil?) || !badges_api_page.reg_status.nil?

              has_no_blocks_message = my_academics_page.no_active_blocks_message?

              it ("shows no block alert on the profile popover for UID #{uid}") { expect(has_block_alert).to be false }
              it ("shows a no active blocks message for UID #{uid}") { expect(has_no_blocks_message).to be true }

            else

              has_blocks_heading = my_academics_page.active_blocks_heading?

              it ("has no blocks section for UID #{uid}") { expect(has_blocks_heading).to be false }

            end

            # BLOCK HISTORY

            has_show_block_history_button = my_academics_page.show_block_history_button?
            has_block_history = academics_api_page.inactive_blocks.any? unless academics_api_page.inactive_blocks.nil?

            if has_block_history && status_api_page.has_academics_tab?

              it ("shows a show-block-history button for UID #{uid}") { expect(has_show_block_history_button).to be true }

              my_academics_page.show_block_history

              acad_page_inact_block_types = my_academics_page.inactive_block_types
              acad_page_inact_block_dates = my_academics_page.inactive_block_dates
              acad_page_inact_block_clears = my_academics_page.inactive_block_cleared_dates

              acad_api_inact_block_types = academics_api_page.inactive_block_types
              acad_api_inact_block_dates = academics_api_page.inactive_block_dates
              acad_api_inact_block_clears = academics_api_page.inactive_block_cleared_dates

              has_hide_block_history_button = my_academics_page.hide_block_history_button?
              my_academics_page.hide_block_history
              block_history_visible = my_academics_page.inactive_blocks_table_element.visible?

              it ("shows the inactive block type on the academics page for UID #{uid}") { expect(acad_page_inact_block_types).to eql(acad_api_inact_block_types) }
              it ("shows the inactive block date on the academics page for UID #{uid}") { expect(acad_page_inact_block_dates).to eql(acad_api_inact_block_dates) }
              it ("shows the inactive block cleared date on the academics page for UID #{uid}") { expect(acad_page_inact_block_clears).to eql(acad_api_inact_block_clears) }
              it ("shows a hide-block-history button for UID #{uid}") { expect(has_hide_block_history_button).to be true }
              it ("allows UID #{uid} to hide block history") { expect(block_history_visible).to be false }

            # If user has reg status or if user has no reg status but has a hold, the blocks history messaging still appears
            elsif !badges_api_page.reg_status_summary.nil? || (badges_api_page.reg_status_summary.nil? && has_active_hold)

              has_no_block_history_message = my_academics_page.no_inactive_blocks_message?

              it ("shows no show-block-history button for UID #{uid}") { expect(has_show_block_history_button).to be false }
              it ("shows a no block history message on the academics page for UID #{uid}") { expect(has_no_block_history_message).to be true }
            end

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

            if has_block_alert
              my_dashboard_page.load_page
              my_dashboard_page.open_profile_popover
              my_dashboard_page.click_block_status_alert
              block_alert_link_works = my_academics_page.active_blocks_table_element.when_visible timeout

              it ("offers a link from the profile popover active block alert to My Academics for UID #{uid}") { expect(block_alert_link_works).to be_truthy }
            end

          elsif is_ex_student && !status_api_page.is_faculty?

            it ("is available via a person icon in the header for UID #{uid}") { expect(has_status_heading).to be true }
            it ("shows no block alert on the popover for UID #{uid}") { expect(has_block_alert).to be false }
            it ("shows no registration alert on the popover for UID #{uid}") { expect(has_reg_alert).to be false }

          else

            it ("is not available via a person icon in the header for UID #{uid}") { expect(has_status_heading).to be false }

          end

        rescue => e
          logger.error "#{e.message + "\n"} #{e.backtrace.join("\n ")}"
        ensure
          test_output_row = [uid, affiliations * ', ', is_student, is_ex_student, is_registered, api_reg_status, api_reg_status_summary,
                             api_res_status, has_active_hold, hold_reasons * ', ', has_active_block, block_types, has_block_history]
          UserUtils.add_csv_row(test_output, test_output_row)
        end
      end

      it ('shows "Registered" for at least one of the test UIDs') { expect(registered_users.any?).to be true }
      it ('shows "Resident" for at least one of the test UIDs') { expect(resident_users.any?).to be true }

    rescue => e
      logger.error "#{e.message + "\n"} #{e.backtrace.join("\n ")}"
    ensure
      WebDriverUtils.quit_browser driver
    end
  end
end
