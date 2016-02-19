describe 'Delegated access', :testui => true do

  if ENV['UI_TEST'] && Settings.ui_selenium.layer == 'local'

    include ClassLogger

    begin
      @driver = WebDriverUtils.launch_browser
      timeout = WebDriverUtils.page_load_timeout
      wait = Selenium::WebDriver::Wait.new timeout

      @splash_page = CalCentralPages::SplashPage.new @driver
      @basic_info_page = CalCentralPages::MyProfileBasicInfoCard.new @driver
      @delegate_access_page = CalCentralPages::MyProfileDelegateAccessCard.new @driver
      @status_api = ApiMyStatusPage.new @driver

      # ALL USER ROLES - verify access to 'Delegate Access'

      test_users = UserUtils.load_delegated_access_users
      test_users.each do |user|
        uid = user['uid']
        logger.info "Test UID is #{uid}"
        user_roles = user['delegatedAccess']['roles']

        begin
          @splash_page.load_page
          @splash_page.basic_auth uid
          @status_api.get_json @driver

          # Verify validity of test data to assist test maintenance
          is_student = @status_api.is_student?
          it ("test data thinks UID #{uid} is a student but the status API disagrees") { fail } if user_roles['student'] && !is_student

          is_concurrent = @status_api.is_concurrent_enroll_student?
          it ("test data thinks UID #{uid} is a concurrent enrollment student but the status API disagrees") { fail } if user_roles['concurrentEnrollment'] && !is_concurrent

          is_ex_student = @status_api.is_ex_student?
          it ("test data thinks UID #{uid} is an ex-student but the status API disagrees") { fail } if user_roles['exStudent'] && !is_ex_student

          is_faculty = @status_api.is_faculty?
          it ("test data thinks UID #{uid} is faculty but the status API disagrees") { fail } if user_roles['faculty'] && !is_faculty

          is_staff = @status_api.is_staff?
          it ("test data thinks UID #{uid} is staff but the status API disagrees") { fail } if user_roles['staff'] && !is_staff

          is_advisor = @status_api.is_advisor?
          it ("test data thinks UID #{uid} is an advisor but the status API disagrees") { fail } if user_roles['advisor'] && !is_advisor

          is_delegate = @status_api.is_delegate?
          it ("test data thinks UID #{uid} is a delegate but the status API disagrees") { fail } if user_roles['delegate'] && !is_delegate

          @basic_info_page.load_page
          @basic_info_page.sidebar_element.when_visible timeout
          has_delegate_access = @basic_info_page.delegate_access_link?

          if user_roles['student']

            it "offers a 'Delegate Access' Profile menu option to UID #{uid}" do
              expect(has_delegate_access).to be true
            end

            @basic_info_page.click_delegate_access @driver
            @delegate_access_page.manage_delegates_msg_element.when_visible timeout

            has_manage_delegates_link = @delegate_access_page.manage_delegates_link?
            it "offers link to Manage Delegates for UID #{uid}" do
              expect(has_manage_delegates_link).to be true
            end
            has_share_bcal_link = WebDriverUtils.verify_external_link(@driver, @delegate_access_page.bcal_link_element, 'Share your calendar with someone - Calendar Help')
            it "offers a link to instructions for sharing bCal to UID #{uid}" do
              expect(has_share_bcal_link).to be true
            end

          else

            it "offers no Profile menu Delegate Access option to UID #{uid}" do
              expect(has_delegate_access).to be false
            end

            @delegate_access_page.load_page
            @delegate_access_page.wait_until(timeout) { @delegate_access_page.title == 'Error | CalCentral' }

            hits_delegate_404 = @delegate_access_page.not_found?
            it "prevents UID #{uid} from hitting the Delegate Access page directly" do
              expect(hits_delegate_404).to be true
            end

          end
        rescue => e
          logger.error e.message + "\n" + e.backtrace.join("\n")
        end
      end

      # DELEGATES - verify the available CalCentral UI when delegates are viewing-as

      @dashboard_page = CalCentralPages::MyDashboardPage.new @driver
      @campus_page = CalCentralPages::MyCampusPage.new @driver
      @toolbox_page = CalCentralPages::MyToolboxPage.new @driver

      # Academics UI
      @academic_profile_card = CalCentralPages::MyAcademicsProfileCard.new @driver
      @status_card = CalCentralPages::MyAcademicsStatusAndBlocksCard.new @driver
      @semester_card = CalCentralPages::MyAcademicsSemestersCard.new @driver
      @final_exams_card = CalCentralPages::MyAcademicsFinalExamsCard.new @driver
      @advising_card = CalCentralPages::MyAcademicsAdvisingCard.new @driver
      @uni_reqts_card = CalCentralPages::MyAcademicsUniversityReqtsCard.new @driver
      @final_grades_card = CalCentralPages::MyAcademicsFinalGradesCard.new @driver
      @gpa_calc_card = CalCentralPages::MyAcademicsGPACalcCard.new @driver
      @classes_card = CalCentralPages::MyAcademicsClassesCard.new @driver
      @teaching_card = CalCentralPages::MyAcademicsTeachingCard.new @driver
      @class_page = CalCentralPages::MyAcademicsClassPage.new @driver
      @academics_api = ApiMyAcademicsPageSemesters.new @driver

      # Finances UI
      @finances_page = CalCentralPages::MyFinancesPages::MyFinancesLandingPage.new @driver
      @finances_details_page = CalCentralPages::MyFinancesPages::MyFinancesDetailsPage.new @driver
      @finances_fin_aid_page = CalCentralPages::MyFinancesPages::MyFinancesFinancialAidPage.new @driver
      @financials_api = ApiMyFinancialsPage.new @driver
      @cal_1_card_api = ApiMyCal1CardPage.new @driver
      @my_fin_aid_api = ApiMyFinAidPage.new @driver
      @cs_fin_aid_years_api = ApiCSAidYearsPage.new @driver
      @cs_fin_aid_data_api = ApiCSFinAidDataPage.new @driver

      test_delegates = test_users.select { |user| user['delegatedAccess']['roles']['delegate'] }
      test_delegates.each do |delegate|

        begin
          uid = delegate['uid']
          logger.info("Delegate UID is #{uid}")
          delegate_students = delegate['delegatedAccess']['students']

          @splash_page.basic_auth uid
          @toolbox_page.load_page

          # TODO - Verify welcome message and expandable instructions
          # TODO - Verify that the students listed on the Toolbox are exactly the expected students
          # TODO - Verify Academic dates and deadlines
          # TODO - Verify quick links

          if delegate_students.any?
            logger.debug "There are #{delegate_students.length} student accounts associated with the delegate"

            delegate_students.each do |student|
              student_uid = student['uid']
              student_privileges = student['privileges']

              begin
                logger.info "Delegate UID #{uid} is viewing as student UID #{student_uid}"
                @toolbox_page.view_as_user student_uid
                @toolbox_page.stop_viewing_as_element.when_visible timeout

                current_url = @driver.current_url
                if student_privileges['enrollment'] || student_privileges['grades']
                  it "lands delegate UID #{uid} on the Academics page for UID #{student_uid}" do
                    expect(current_url).to eql("#{WebDriverUtils.base_url}/academics")
                  end

                  @academics_api.get_json @driver
                  @academic_profile_card.load_page
                  @academic_profile_card.profile_card_element.when_visible timeout

                  # Academic Profile
                  shows_profile_name = @academic_profile_card.name?
                  it "shows delegate UID #{uid} the academic profile name for UID #{student_uid}" do
                    expect(shows_profile_name).to be true
                  end
                  shows_standing = @academic_profile_card.standing?
                  unless @academics_api.has_no_standing?
                    it "shows delegate UID #{uid} the academic standing for UID #{student_uid}" do
                      expect(shows_standing).to be true
                    end
                  end
                  shows_gpa = @academic_profile_card.gpa?
                  unless @academics_api.gpa == '0.0' || !student_privileges['grades']
                    it "shows delegate UID #{uid} the academic GPA for UID #{student_uid}" do
                      expect(shows_gpa).to be true
                    end
                  end

                  # Status and Holds
                  shows_reg_status = @status_card.status_table?
                  it "shows delegate UID #{uid} the registration status for UID #{student_uid}" do
                    expect(shows_reg_status).to be true
                  end
                  shows_active_blocks = @status_card.active_blocks_table?
                  it "shows delegate UID #{uid} the active blocks for UID #{student_uid}" do
                    expect(shows_active_blocks).to be true
                  end

                  # Final Exams
                  if @academics_api.has_exam_schedules
                    shows_exams = @final_exams_card.all_exam_courses.any?
                    it "shows delegate UID #{uid} the final exams for UID #{student_uid}" do
                      expect(shows_exams).to be true
                    end
                  end

                  # L&S Advising
                  if @academics_api.colleges.include? 'College of Letters & Science'
                    shows_advising = @advising_card.make_appt_link?
                    it "shows delegate UID #{uid} the L and S advising card for UID #{student_uid}" do
                      expect(shows_advising).to be true
                    end
                  end

                  # University Requirements
                  shows_uni_reqts = @uni_reqts_card.reqts_table?
                  if @academics_api.standing == 'Undergraduate'
                    it "shows delegate UID #{uid} the university requirements for UID #{student_uid}" do
                      expect(shows_uni_reqts).to be true
                    end
                  end

                  # My Academics student semester cards

                  student_semesters = @academics_api.all_student_semesters
                  if student_semesters.any?

                    api_semesters = @academics_api.all_student_semesters
                    api_semesters_count = api_semesters.length
                    api_semesters_count += 1 if @academics_api.addl_credits
                    ui_semesters_count = @semester_card.semester_card_elements.length

                    it "shows delegate UID #{uid} all the semester cards for UID #{student_uid}" do
                      expect(ui_semesters_count).to eql(api_semesters_count)
                    end

                    @academics_api.all_student_semesters.each do |semester|
                      semester_name = @academics_api.semester_name semester
                      semester_courses = @academics_api.semester_card_courses(semester, @academics_api.semester_courses(semester))

                      ui_grades = @semester_card.grades(@driver, semester_name)
                      api_grades = @academics_api.semester_grades(api_semesters, semester_courses, semester)

                      if student_privileges['grades']
                        it "shows delegate UID #{uid} the #{semester_name} grades on My Academics for UID #{student_uid}" do
                          expect(ui_grades).to eql(api_grades)
                        end
                      else
                        it "shows delegate UID #{uid} no #{semester_name} grades on My Academics for UID #{student_uid}" do
                          expect(ui_grades.any?).to be false
                        end
                      end

                      # Student semester pages

                      if @academics_api.has_enrollment_data? semester
                        @semester_card.click_student_semester_link semester
                        ui_course_codes = @semester_card.all_enrolled_course_codes
                        it "shows delegate UID #{uid} the #{semester_name} enrollment on the semester page for UID #{student_uid}" do
                          expect(ui_course_codes.any?).to be true
                        end

                        ui_course_grades = @final_grades_card.grade_elements
                        shows_gpa_calc = @gpa_calc_card.cum_gpa?
                        if student_privileges['grades']
                          if @academics_api.past_semesters(student_semesters).include?(semester)
                            it "shows delegate UID #{uid} the #{semester_name} final grades on the semester page for UID #{student_uid}" do
                              expect(ui_course_grades.any?).to be true
                            end
                          else
                            it "shows delegate UID #{uid} the #{semester_name} GPA calculator on the semester page for UID #{student_uid}" do
                              expect(shows_gpa_calc).to be true
                            end
                          end
                        else
                          it "shows delegate UID #{uid} no #{semester_name} final grades on the semester page for UID #{student_uid}" do
                            expect(ui_course_grades.any?).to be false
                          end
                          it "shows delegate UID #{uid} no #{semester_name} GPA calculator on the semester page for UID #{student_uid}" do
                            expect(shows_gpa_calc).to be false
                          end
                        end

                        # Student class pages

                        semester_courses.each do |course|
                          api_course_code = @academics_api.course_code course
                          api_course_title = @academics_api.course_title course

                          # Course with multiple primary sections
                          if @academics_api.multiple_primaries? course
                            @academics_api.course_primary_sections(course).each do |prim_section|
                              class_page_url = @academics_api.section_url prim_section
                              @semester_card.click_class_link_by_url class_page_url
                              @class_page.class_info_heading_element.when_visible timeout
                              ui_course_title = @class_page.course_title
                              it "shows delegate UID #{uid} class info on the #{semester_name} #{api_course_code} class page for UID #{student_uid}" do
                                expect(ui_course_title).to eql(api_course_title)
                              end

                              # Webcast
                              shows_course_captures = @class_page.course_capture_heading?
                              it "shows delegate UID #{uid} a course capture card on the #{semester_name} #{api_course_code} class page for UID #{student_uid}" do
                                expect(shows_course_captures).to be true
                              end

                              # Textbooks
                              shows_textbooks = @class_page.textbooks_heading?
                              it "shows delegate UID #{uid} a textbooks card on the #{semester_name} #{api_course_code} class page for UID #{student_uid}" do
                                expect(shows_textbooks).to be true
                              end

                              @class_page.back
                            end

                          # Course with a single primary section
                          else
                            class_page_url = @academics_api.course_url course
                            @semester_card.click_class_link_by_url class_page_url
                            @class_page.class_info_heading_element.when_visible timeout
                            ui_course_title = @class_page.course_title
                            it "shows delegate UID #{uid} class info on the #{semester_name} #{api_course_code} class page for UID #{student_uid}" do
                              expect(ui_course_title).to eql(api_course_title)
                            end

                            # Webcast
                            shows_course_captures = @class_page.course_capture_heading?
                            it "shows delegate UID #{uid} a course capture card on the #{semester_name} #{api_course_code} class page for UID #{student_uid}" do
                              expect(shows_course_captures).to be true
                            end

                            # Textbooks
                            shows_textbooks = @class_page.textbooks_heading?
                            it "shows delegate UID #{uid} a textbooks card on the #{semester_name} #{api_course_code} class page for UID #{student_uid}" do
                              expect(shows_textbooks).to be true
                            end

                            @class_page.back
                          end
                        end
                      end

                      @semester_card.back
                    end
                  end

                  # My Academics teaching semester cards

                  teaching_semesters = @academics_api.all_teaching_semesters
                  if teaching_semesters.any?
                    if student_semesters.any?

                      # No (teaching) Classes Card should be shown on the My Academics page
                      shows_teaching_classes =@classes_card.all_semester_course_codes.any?
                      it "shows delegate UID #{uid} no teaching classes on the My Academics page for UID #{student_uid}" do
                        expect(shows_teaching_classes).to be false
                      end

                      # No Teaching Card should be shown on the My Academics page
                      shows_teaching_card = @teaching_card.teaching_course_code_elements.any?
                      it "shows delegate UID #{uid} no teaching card on the My Academics page for UID #{student_uid}" do
                        expect(shows_teaching_card).to be false
                      end

                      # Attempt to hit teaching semester and teaching class pages directly


                      first_semester_slug = @academics_api.semester_slug teaching_semesters[0]
                      @driver.get "#{WebDriverUtils.base_url}/academics/semester/#{first_semester_slug}"
                      wait.until { @driver.title == 'Error | CalCentral' }

                      class_page = "#{WebDriverUtils.base_url}/#{@academics_api.course_url @academics_api.semester_courses(teaching_semesters[0])}"
                      @driver.get class_page
                      wait.until { @driver.title == 'Error | CalCentral' }

                    end
                  end

                  @academic_profile_card.click_my_finances_link if student_privileges['finances']

                elsif student_privileges['finances']

                  it "lands delegate UID #{uid} on the Finances page" do
                    expect(current_url).to eql("#{WebDriverUtils.base_url}/finances")
                  end

                end

                if student_privileges['finances']

                  it "lands delegate UID #{uid} with 'finances-only' privileges on My Finances" do
                    expect(current_url).to eql("#{WebDriverUtils.base_url}/finances")
                  end

                  # Billing Summary
                  @finances_page.billing_summary_spinner_element.when_not_visible timeout
                  sees_billing_summary = @finances_page.account_balance_element?
                  it "shows delegate UID #{uid} the billing summary for UID #{student_uid}" do
                    expect(sees_billing_summary).to be true
                  end
                  sees_payment_button = @finances_page.make_payment_link?
                  it "shows delegate UID #{uid} the 'Make a Payment' button for UID #{student_uid}" do
                    expect(sees_payment_button).to be true
                  end

                  # Cal 1 Card
                  @finances_page.cal_1_card_content_element.when_visible timeout
                  if @cal_1_card_api.has_debit_account?
                    sees_cal_1_card = @finances_page.debit_account_header?
                    it "shows delegate UID #{uid} the Cal 1 Card card for UID #{student_uid}" do
                      expect(sees_cal_1_card).to be true
                    end
                  end

                  # FinAid Messages (legacy)
                  @finances_page.fin_messages_heading_element.when_visible timeout
                  if @my_fin_aid_api.all_activity.any?
                    shows_finaid_msgs = @finances_page.fin_messages_list?
                    it "shows delegate UID #{uid} the MyFinAid messages card for UID #{student_uid}" do
                      expect(shows_finaid_msgs).to be true
                    end
                  end

                  # Financial Resources links
                  @finances_page.fin_resources_list_element.when_visible timeout
                  shows_fin_resources = @finances_page.fin_resources_list?
                  it "shows delegate UID #{uid} Financial Resources link for UID #{student_uid}" do
                    expect(shows_fin_resources).to be true
                  end

                  # Financial Aid (CS)
                  if @cs_fin_aid_years_api.fin_aid_years.any?
                    @finances_page.finaid_content_element.when_visible timeout
                    if @cs_fin_aid_years_api.t_and_c_approval @cs_fin_aid_years_api.fin_aid_years.last
                      # TODO - Finances - FinAid - SIS - sees all if "finances" but no CS links
                      it "shows delegate UID #{uid} Financial Aid info for UID #{student_uid}"

                    end
                  end

                  # Billing - Detail
                  @finances_details_page.load_page
                  @finances_details_page.billing_summary_spinner_element.when_not_visible timeout

                  sees_details_summary = @finances_details_page.account_balance_element?
                  it "shows delegate UID #{uid} the billing summary on the Details page for UID #{student_uid}" do
                    expect(sees_details_summary).to be true
                  end
                  sees_transactions = @finances_details_page.transaction_table?
                  it "shows delegate UID #{uid} the list of transactions on the Details page for UID #{student_uid}" do
                    expect(sees_transactions).to be true
                  end

                end

                # My Dashboard

                has_dashboard = @finances_page.my_dashboard_link?
                it "shows delegate UID #{uid} no My Dashboard link for UID #{student_uid}" do
                  expect(has_dashboard).to be false
                end

                @dashboard_page.load_page
                @dashboard_page.wait_until(timeout) { @dashboard_page.title == 'Error | CalCentral' }

                hits_dashboard_404 = @dashboard_page.not_found?
                it "prevents delegate UID #{uid} from the hitting the Dashboard for UID #{student_uid} directly" do
                  expect(hits_dashboard_404).to be true
                end

                # My Campus

                @campus_page.load_page
                @campus_page.academic_heading_element.when_visible?

                sees_campus_links = @campus_page.links_list?
                it "shows delegate UID #{uid} My Campus links for UID #{student_uid}" do
                  expect(sees_campus_links).to be true
                end

                # bConnected badges

                @campus_page.click_email_badge
                shows_bconnected = @campus_page.email_not_connected_heading_element.visible?
                it "shows delegate UID #{uid} no bConnected email for UID #{student_uid}" do
                  expect(shows_bconnected).to be false
                end

                # Profile

                shows_profile_popover = @campus_page.profile_icon?
                it "shows delegate UID #{uid} no Profile popover for UID #{student_uid}" do
                  expect(shows_profile_popover).to be false
                end

                shows_profile_link = @campus_page.profile_link?
                it "shows delegate UID #{uid} no Profile link for UID #{student_uid}" do
                  expect(shows_profile_link).to be false
                end

                # Miscellaneous tools

                @driver.get "#{WebDriverUtils.base_url}/canvas/embedded/site_creation"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_site_creation = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the Canvas site creation page for UID #{student_uid}" do
                  expect(shows_site_creation).to be false
                end

                @driver.get "#{WebDriverUtils.base_url}/canvas/embedded/create_course_site"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_create_course_site = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the Canvas create a course site page for UID #{student_uid}" do
                  expect(shows_create_course_site).to be false
                end

                @driver.get "#{WebDriverUtils.base_url}/canvas/embedded/create_project_site"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_create_project_site = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the Canvas create a project site page for UID #{student_uid}" do
                  expect(shows_create_project_site).to be false
                end

                @driver.get "#{WebDriverUtils.base_url}/canvas/embedded/user_provision"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_user_provision = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the Canvas user provisioning page for UID #{student_uid}" do
                  expect(shows_user_provision).to be false
                end

                # TODO - Canvas - find user to add
                @driver.get "#{WebDriverUtils.base_url}/canvas/embedded/course_add_user"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_course_add_user = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the Canvas find a user to add page for UID #{student_uid}" do
                  expect(shows_course_add_user).to be false
                end

                # TODO - Canvas - webcasts
                @driver.get "#{WebDriverUtils.base_url}/canvas/embedded/course_mediacasts"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_mediacasts = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the Canvas course captures page for UID #{student_uid}" do
                  expect(shows_mediacasts).to be false
                end

                # TODO - Canvas - official sections
                @driver.get "#{WebDriverUtils.base_url}/canvas/embedded/course_manage_official_sections"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_official_sections = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the Canvas official sections page for UID #{student_uid}" do
                  expect(shows_official_sections).to be false
                end

                # TODO - Canvas - roster photos
                @driver.get "#{WebDriverUtils.base_url}/canvas/embedded/rosters"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_roster_photos = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the Canvas roster photos page for UID #{student_uid}" do
                  expect(shows_roster_photos).to be false
                end

                # TODO - Canvas - export E-Grades
                @driver.get "#{WebDriverUtils.base_url}/canvas/embedded/course_grade_export"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_e_grades = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the Canvas E-Grades export page for UID #{student_uid}" do
                  expect(shows_e_grades).to be false
                end

                @driver.get "#{WebDriverUtils.base_url}/oec"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_oec = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the OEC page for UID #{student_uid}" do
                  expect(shows_oec).to be false
                end

                @driver.get "#{WebDriverUtils.base_url}/ccadmin"
                wait.until { @driver.title == 'Error | CalCentral' }
                shows_ccadmin = @campus_page.not_found?
                it "prevents UID #{uid} from reaching the CCAdmin page for UID #{student_uid}" do
                  expect(shows_ccadmin).to be false
                end

              rescue => e
                logger.error e.message + "\n" + e.backtrace.join("\n")
              end
            end
          else
            # Verify Toolbox view if you have no students
          end
        rescue => e
          logger.error e.message + "\n" + e.backtrace.join("\n")
        end
      end
    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n ")
    ensure
      WebDriverUtils.quit_browser(@driver)
    end
  end
end
