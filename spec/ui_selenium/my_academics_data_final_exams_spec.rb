describe 'My Academics Final Exams card', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      driver = WebDriverUtils.launch_browser
      test_users = UserUtils.load_test_users
      testable_users = []
      test_output_heading = ['UID', 'Has Exams', 'Exam Dates', 'Exam Times', 'Exam Courses', 'Exam Locations']
      test_output = UserUtils.initialize_output_csv(self, test_output_heading)

      test_users.each do |user|
        if user['finalExams']
          uid = user['uid']
          logger.info("UID is #{uid}")
          has_exams = false
          api_exam_dates = []
          api_exam_times = []
          api_exam_courses = []
          api_exam_locations = []

          begin
            splash_page = CalCentralPages::SplashPage.new driver
            splash_page.load_page
            splash_page.basic_auth uid
            status_api = ApiMyStatusPage.new driver
            status_api.get_json driver
            academics_api = ApiMyAcademicsPage.new driver
            academics_api.get_json driver
            if status_api.is_student?
              classes_api = ApiMyClassesPage.new driver
              classes_api.get_json driver
              current_term = classes_api.current_term
              my_academics_page = CalCentralPages::MyAcademicsPage::MyAcademicsFinalExamsCard.new driver
              my_academics_page.load_page
              my_academics_page.page_heading_element.when_visible WebDriverUtils.academics_timeout
              if academics_api.has_exam_schedules
                has_exams = true
                testable_users << uid

                # EXAM SCHEDULES ON MY ACADEMICS LANDING PAGE
                api_exam_dates = academics_api.all_exam_dates
                api_exam_times = academics_api.all_exam_times
                api_exam_courses = academics_api.all_exam_courses
                api_exam_locations = academics_api.all_exam_locations
                acad_exam_dates = my_academics_page.all_exam_dates
                acad_exam_times = my_academics_page.all_exam_times
                acad_exam_courses = my_academics_page.all_exam_courses
                acad_exam_locations = my_academics_page.all_exam_locations
                it "shows the right exam dates on My Academics for UID #{uid}" do
                  expect(acad_exam_dates).to eql(api_exam_dates)
                end
                it "shows the right exam times on My Academics for UID #{uid}" do
                  expect(acad_exam_times).to eql(api_exam_times)
                end
                it "shows the right exam courses on My Academics for UID #{uid}" do
                  expect(acad_exam_courses).to eql(api_exam_courses)
                end
                it "shows the right exam locations on My Academics for UID #{uid}" do
                  expect(acad_exam_locations).to eql(api_exam_locations)
                end

                # IF LINKED LOCATIONS EXIST, VERIFY THAT ONE OF LINKS OPENS GOOGLE MAPS IN NEW WINDOW
                exam_location_links = my_academics_page.exam_location_links_elements
                unless exam_location_links.empty?
                  link_works = WebDriverUtils.verify_external_link(driver, exam_location_links.first, 'Google Maps')
                  it "offers a Google Maps link on My Academics for UID #{uid}" do
                    expect(link_works).to be true
                  end
                end

                # EXAM SCHEDULES ON SEMESTER PAGE
                my_academics_page.click_student_semester_link current_term
                my_academics_page.final_exams_card_heading_element.when_visible WebDriverUtils.page_load_timeout
                semester_exam_dates = my_academics_page.all_exam_dates
                semester_exam_times = my_academics_page.all_exam_times
                semester_exam_courses = my_academics_page.all_exam_courses
                semester_exam_locations = my_academics_page.all_exam_locations
                it "shows the right exam dates on the semester page for UID #{uid}" do
                  expect(semester_exam_dates).to eql(api_exam_dates)
                end
                it "shows the right exam times on the semester page for UID #{uid}" do
                  expect(semester_exam_times).to eql(api_exam_times)
                end
                it "shows the right exam courses on the semester page for UID #{uid}" do
                  expect(semester_exam_courses).to eql(api_exam_courses)
                end
                it "shows the right exam locations on the semester page for UID #{uid}" do
                  expect(semester_exam_locations).to eql(api_exam_locations)
                end

              else
                has_finals_card = my_academics_page.final_exams_card_heading_element.visible?
                it "shows no final exams card for UID #{uid}" do
                  expect(has_finals_card).to be false
                end
              end
            end
          rescue => e
            logger.error e.message + "\n" + e.backtrace.join("\n")
          ensure
            test_output_row = [uid, has_exams, api_exam_dates * ', ', api_exam_times * ', ', api_exam_courses * ', ', api_exam_locations * ', ']
            UserUtils.add_csv_row(test_output, test_output_row)
          end
        end
      end
      it 'has final exams info for at least one of the test UIDs' do
        expect(testable_users.any?).to be true
      end
    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n")
    ensure
      WebDriverUtils.quit_browser driver
    end
  end
end
