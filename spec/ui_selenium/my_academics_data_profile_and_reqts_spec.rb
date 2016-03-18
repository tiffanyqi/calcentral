describe 'My Academics profile and university requirements cards', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      driver = WebDriverUtils.launch_browser
      test_output = UserUtils.initialize_output_csv(self)
      test_users = UserUtils.load_test_users
      testable_users = []

      CSV.open(test_output, 'wb') do |user_info_csv|
        user_info_csv << ['UID', 'User Type', 'Term Transition', 'Colleges', 'Majors', 'Careers', 'Units', 'Level', 'Level No AP']
      end

      test_users.each do |user|
        if user['profile']
          uid = user['uid'].to_s
          logger.info("UID is #{uid}")
          user_type = nil
          term_transition = false
          api_careers = []
          api_colleges = []
          api_majors = []
          api_level = nil
          api_units = nil

          begin
            splash_page = CalCentralPages::SplashPage.new(driver)
            splash_page.load_page
            splash_page.basic_auth uid
            status_api_page = ApiMyStatusPage.new(driver)
            status_api_page.get_json(driver)
            academics_api_page= ApiMyAcademicsPageSemesters.new(driver)
            academics_api_page.get_json(driver)
            profile_card = CalCentralPages::MyAcademicsProfileCard.new(driver)
            reqts_card = CalCentralPages::MyAcademicsUniversityReqtsCard.new(driver)
            profile_card.load_page

            if (status_api_page.has_academics_tab? && status_api_page.is_student?) || status_api_page.has_student_history?
              profile_card.profile_card_element.when_visible WebDriverUtils.academics_timeout

              testable_users << uid unless academics_api_page.transition_term?

              # NAME
              api_full_name = status_api_page.full_name
              my_academics_full_name = profile_card.name
              it "show the full name of UID #{uid}" do
                expect(my_academics_full_name).to eql(api_full_name)
              end

              # GPA
              if academics_api_page.gpa == '0.0' || status_api_page.is_concurrent_enroll_student?
                has_gpa = profile_card.gpa?
                it "show no GPA for UID #{uid}" do
                  expect(has_gpa).to be false
                end
              else
                api_gpa = academics_api_page.gpa
                shows_gpa = profile_card.gpa_element.visible?
                it "hide the GPA by default for UID #{uid}" do
                  expect(shows_gpa).to be false
                end

                profile_card.show_gpa
                gpa_revealed = profile_card.gpa_element.when_visible WebDriverUtils.page_event_timeout
                my_academics_gpa = profile_card.gpa
                it "show the GPA for UID #{uid} when a user clicks 'Show'" do
                  expect(gpa_revealed).to be_truthy
                  expect(my_academics_gpa).to eql(api_gpa)
                end

                profile_card.hide_gpa
                gpa_hidden = profile_card.gpa_element.when_not_visible WebDriverUtils.page_event_timeout
                it "hide the GPA for UID #{uid} when a user clicks 'Hide'" do
                  expect(gpa_hidden).to be_truthy
                end
              end

              # UNITS
              if academics_api_page.ttl_units.nil? || (academics_api_page.has_no_standing? && academics_api_page.ttl_units.zero?)
                has_units = profile_card.units?
                it "show no units for UID #{uid}" do
                  expect(has_units).to be false
                end
              else
                api_units = academics_api_page.ttl_units.to_s
                my_academics_units = profile_card.units
                it "show the units for UID #{uid}" do
                  expect(my_academics_units).to eql(api_units)
                end
              end

              # STANDING
              unless academics_api_page.has_no_standing?
                api_colleges = academics_api_page.colleges
                api_majors = academics_api_page.majors
                api_careers = academics_api_page.careers
                api_level = academics_api_page.level
                my_academics_colleges = profile_card.all_colleges
                my_academics_majors = profile_card.all_majors
                my_academics_careers = profile_card.all_careers
                my_academics_level = profile_card.level
                it "show the colleges for UID #{uid}" do
                  expect(my_academics_colleges).to eql(api_colleges)
                end
                it "show the majors for UID #{uid}" do
                  expect(my_academics_majors).to eql(api_majors)
                end
                it "show the careers for UID #{uid}" do
                  expect(my_academics_careers).to eql(api_careers)
                end

                # LEVEL - AP and NON-AP
                it "show the level for UID #{uid}" do
                  expect(my_academics_level).to eql(api_level)
                end
                api_level_no_ap = academics_api_page.non_ap_level
                if api_level_no_ap.nil?
                  has_level_no_ap = profile_card.level_non_ap?
                  it "show no level without AP credit for grad UID #{uid}" do
                    expect(has_level_no_ap).to be false
                  end
                else
                  my_academics_level_no_ap = profile_card.level_non_ap
                  it "show the level without AP credit for undergrad UID #{uid}" do
                    expect(my_academics_level_no_ap).to eql(api_level_no_ap)
                  end
                end
              end

              # UNDERGRAD REQUIREMENTS

              if academics_api_page.has_no_standing? || (!academics_api_page.careers.include? 'Undergraduate')

                has_reqts_card = reqts_card.reqts_table?
                it "show no 'University Requirements' UI for UID #{uid}" do
                  expect(has_reqts_card).to be false
                end

              else

                if academics_api_page.writing_reqt_met?
                  my_academics_writing_met = reqts_card.writing_reqt_met?
                  it "show 'UC Entry Level Writing' 'Completed' for UID #{uid}" do
                    expect(my_academics_writing_met).to be true
                  end
                else
                  my_academics_writing_unmet = reqts_card.writing_reqt_unmet?
                  writing_unmet_link_works = WebDriverUtils.verify_external_link(driver, reqts_card.writing_reqt_unmet_element, 'Undergraduate Degree Requirements - Office Of The Registrar')
                  it "show 'UC Entry Level Writing' 'Incomplete' for UID #{uid}" do
                    expect(my_academics_writing_unmet).to be true
                  end
                  it "offers a link to degree requirements for UID #{uid}" do
                    expect(writing_unmet_link_works).to be true
                  end
                end

                if academics_api_page.history_reqt_met?
                  my_academics_history_met = reqts_card.history_reqt_met?
                  it "show 'American History' 'Completed' for UID #{uid}" do
                    expect(my_academics_history_met).to be true
                  end
                else
                  my_academics_history_unmet = reqts_card.history_reqt_unmet?
                  history_unmet_link_works = WebDriverUtils.verify_external_link(driver, reqts_card.history_reqt_unmet_element, 'Undergraduate Degree Requirements - Office Of The Registrar')
                  it "show 'American History' 'Incomplete' for UID #{uid}" do
                    expect(my_academics_history_unmet).to be true
                  end
                  it "offer a link to degree requirements for UID #{uid}" do
                    expect(history_unmet_link_works).to be true
                  end
                end

                if academics_api_page.institutions_reqt_met?
                  my_academics_institutions_met = reqts_card.institutions_reqt_met?
                  it "show 'American Institutions' 'Completed' for UID #{uid}" do
                    expect(my_academics_institutions_met).to be true
                  end
                else
                  my_academics_institutions_unmet = reqts_card.institutions_reqt_unmet?
                  institutions_unmet_link_works = WebDriverUtils.verify_external_link(driver, reqts_card.institutions_reqt_unmet_element, 'Undergraduate Degree Requirements - Office Of The Registrar')
                  it "show 'American Institutions' 'Incomplete' for UID #{uid}" do
                    expect(my_academics_institutions_unmet).to be true
                  end
                  it "offer a link to degree requirements for UID #{uid}" do
                    expect(institutions_unmet_link_works).to be true
                  end
                end

                if academics_api_page.cultures_reqt_met?
                  my_academics_cultures_met = reqts_card.cultures_reqt_met?
                  it "show 'American Cultures' 'Completed' for UID #{uid}" do
                    expect(my_academics_cultures_met).to be true
                  end
                else
                  my_academics_cultures_unmet = reqts_card.cultures_reqt_unmet?
                  cultures_unmet_link_works = WebDriverUtils.verify_external_link(driver, reqts_card.cultures_reqt_unmet_element, 'Undergraduate Degree Requirements - Office Of The Registrar')
                  it "show 'American Cultures' 'Incomplete' for UID #{uid}" do
                    expect(my_academics_cultures_unmet).to be true
                  end
                  it "offer a link to degree requirements for UID #{uid}" do
                    expect(cultures_unmet_link_works).to be true
                  end
                end
              end

              # STUDENT STATUS MESSAGING VARIATIONS

              if academics_api_page.has_no_standing?

                if status_api_page.is_student?
                  if status_api_page.is_registered?
                    user_type = 'registered student no standing'
                    has_reg_no_standing_msg = profile_card.reg_no_standing_msg?
                    it "show a registered but not fully active message to UID #{uid}" do
                      expect(has_reg_no_standing_msg).to be true
                    end
                  else
                    if academics_api_page.units_attempted == 0
                      user_type = 'new student'
                      has_non_reg_msg = profile_card.non_reg_student_msg?
                      has_new_student_msg = profile_card.new_student_msg?
                      it "show a 'not registered' message to UID #{uid}" do
                        expect(has_non_reg_msg).to be true
                      end
                      it "show a new student message to UID #{uid}" do
                        expect(has_new_student_msg).to be true
                      end
                    else
                      user_type = 'unregistered student'
                      has_non_reg_msg = profile_card.non_reg_student_msg?
                      it "show a 'not registered' message to UID #{uid}" do
                        expect(has_non_reg_msg).to be true
                      end
                    end
                  end

                elsif status_api_page.is_concurrent_enroll_student?
                  user_type = 'concurrent enrollment'
                  has_concur_student_msg = profile_card.concur_student_msg?
                  has_uc_ext_link = WebDriverUtils.verify_external_link(driver, profile_card.uc_ext_link_element, 'Concurrent Enrollment | Student Services | UC Berkeley Extension')
                  has_eap_link = WebDriverUtils.verify_external_link(driver, profile_card.eap_link_element, 'Exchange Students | Berkeley International Office')
                  it "show a concurrent enrollment student message to UID #{uid}" do
                    expect(has_concur_student_msg).to be true
                  end
                  it "show a concurrent enrollment UC Extension link to UID #{uid}" do
                    expect(has_uc_ext_link).to be true
                  end
                  it "show a concurrent enrollment EAP link to UID #{uid}" do
                    expect(has_eap_link).to be true
                  end

                else
                  user_type = 'ex-student'
                  has_ex_student_msg = profile_card.ex_student_msg?
                  it "show an ex-student message to UID #{uid}" do
                    expect(has_ex_student_msg).to be true
                  end
                end

              else
                if academics_api_page.transition_term? && !academics_api_page.trans_term_profile_current?
                  term_transition = true
                  api_term_transition = "Academic status as of #{academics_api_page.term_name}"
                  if status_api_page.is_student?
                    user_type = 'existing student'
                    my_academics_term_transition = profile_card.term_transition_heading
                    it "show the term transition heading to UID #{uid}" do
                      expect(my_academics_term_transition).to eql(api_term_transition)
                    end
                  else
                    user_type = 'ex-student'
                    has_transition_heading = profile_card.term_transition_heading?
                    it "shows no term transition heading to UID #{uid}" do
                      expect(has_transition_heading).to be false
                    end
                  end
                end
              end

            elsif academics_api_page.all_teaching_semesters.nil?
              user_type = 'no data'
              no_data_msg = profile_card.no_data_heading?
              it "show a 'Data not available' message to UID #{uid}" do
                expect(no_data_msg).to be true
              end

            else
              has_profile_card = profile_card.profile_card?
              it "show no profile card to UID #{uid}" do
                expect(has_profile_card).to be false
              end
            end

          rescue => e
            logger.error e.message + "\n" + e.backtrace.join("\n")
          ensure
            CSV.open(test_output, 'a+') do |user_info_csv|
              user_info_csv << [uid, user_type, term_transition, api_colleges * '; ', api_majors * '; ',
                                api_careers * '; ', api_units, api_level, api_level_no_ap]
            end
          end
        end
      end

      it 'shows academic profile for a current term for at least one of the test UIDs' do
        expect(testable_users.any?).to be true
      end

    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n ")
    ensure
      logger.info('Quitting the browser')
      WebDriverUtils.quit_browser(driver)
    end
  end
end
