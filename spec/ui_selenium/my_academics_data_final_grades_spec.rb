describe 'My Academics transcripts', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      driver = WebDriverUtils.launch_browser
      test_users = UserUtils.load_test_users
      test_output_heading = ['UID', 'Semester', 'Course Code', 'Units', 'Grade']
      test_output = UserUtils.initialize_output_csv(self, test_output_heading)

      test_users.each do |user|
        if user['grades']
          uid = user['uid']
          logger.info "UID is #{uid}"

          begin
            academics_api_page = ApiMyAcademicsPageSemesters.new driver
            splash_page = CalCentralPages::SplashPage.new driver
            classes_card = CalCentralPages::MyAcademicsClassesCard.new driver
            final_grades_card = CalCentralPages::MyAcademicsFinalGradesCard.new driver
            gpa_calculator = CalCentralPages::MyAcademicsGPACalcCard.new driver

            splash_page.load_page
            splash_page.basic_auth uid
            academics_api_page.get_json driver

            semesters = academics_api_page.all_student_semesters
            past_semesters = academics_api_page.past_semesters semesters

            semesters.each do |semester|

              semester_name = academics_api_page.semester_name semester
              semester_courses = academics_api_page.semester_courses semester
              grades = academics_api_page.semester_grades semester_courses

              if academics_api_page.has_enrollment_data? semester

                semester_slug = academics_api_page.semester_slug semester
                classes_card.load_semester_page semester_slug
                classes_card.semester_heading_element.when_visible WebDriverUtils.page_load_timeout

                shows_final_grades_card = final_grades_card.final_grades_heading?
                shows_gpa_calc_card = gpa_calculator.gpa_calc_heading?

                if semester == academics_api_page.current_semester(semesters) && !academics_api_page.colleges.include?('School of Law')

                  it ("show a GPA Calculator card on the #{semester_name} page for UID #{uid}") { expect(shows_gpa_calc_card).to be true }

                  case academics_api_page.gpa
                    when '0'
                      api_gpa = 'N/A'
                    when '4.0'
                      api_gpa = '4'
                    else
                      api_gpa = academics_api_page.gpa
                  end

                  ui_gpa = gpa_calculator.current_gpa
                  it ("show the current cumulative GPA for UID #{uid} on the GPA Calculator card for #{semester_name}") { expect(ui_gpa).to eql(api_gpa) }

                  ui_grade_option_selections = gpa_calculator.all_selected_grade_options driver
                  (ui_grade_option_selections.include? 'A/A+') ? expected_est_gpa = '4.000' : expected_est_gpa = 'N/A'
                  ui_est_gpa = gpa_calculator.est_gpa
                  it ("show the estimated semester GPA for UID #{uid} on the GPA Calculator card for #{semester_name}") { expect(ui_est_gpa).to eql(expected_est_gpa) }

                  courses = academics_api_page.courses_by_primary_section semester_courses
                  course_codes = academics_api_page.course_codes courses
                  units = academics_api_page.units_by_enrollment semester_courses

                  i = 0
                  courses.each do

                    api_course_code = course_codes[i]
                    ui_course_code = final_grades_card.all_classes[i]
                    it ("show the #{api_course_code} course code on the #{semester_name} GPA Calculator card for UID #{uid}") { expect(ui_course_code).to eql(api_course_code) }

                    api_course_units = units[i]
                    ui_course_units = gpa_calculator.all_units[i]
                    it ("show the #{api_course_code} course units on the #{semester_name} GPA Calculator card for UID #{uid}") { expect(ui_course_units).to eql(api_course_units) }

                    # TODO: add GPA Calculator functional tests

                    i += 1

                  end

                elsif past_semesters.include?(semester) && grades.any?

                  courses = academics_api_page.semester_card_courses(semester, semester_courses)
                  course_codes = academics_api_page.course_codes courses
                  units = academics_api_page.semester_card_units semester_courses

                  if gpa_calculator.grade_options_elements.any?
                    it ("show a GPA Calculator card on the #{semester_name} page for UID #{uid}") { expect(shows_gpa_calc_card).to be true }
                  else
                    it ("show a Final Grades card on the #{semester_name} page for UID #{uid}") { expect(shows_final_grades_card).to be true }
                  end

                  i = 0
                  grades.each do |api_course_grade|

                    api_course_code = course_codes[i]
                    ui_course_code = final_grades_card.all_classes[i]
                    it ("show the course code for #{semester_name} #{api_course_code} for UID #{uid}") { expect(ui_course_code).to eql(api_course_code) }

                    api_course_units = units[i]
                    ui_course_units = final_grades_card.all_units[i]
                    it ("show the course units for #{semester_name} #{api_course_code} for UID #{uid}") { expect(ui_course_units).to eql(api_course_units) }

                    ui_course_grade = final_grades_card.all_grades[i]
                    it ("show the course grades for #{semester_name} #{api_course_code} for UID #{uid}") { expect(ui_course_grade).to eql(api_course_grade) }

                    test_output_row = [uid, semester_name, api_course_code, api_course_units, api_course_grade]
                    UserUtils.add_csv_row(test_output, test_output_row)

                    i += 1

                  end

                else

                  it ("show no Final Grades card on the #{semester_name} page for UID #{uid}") { expect(shows_final_grades_card).to be false }
                  it ("show no GPA Calculator card on the #{semester_name} page for UID #{uid}") { expect(shows_gpa_calc_card).to be false }

                end

                if past_semesters.include? semester && grades.empty?

                  shows_no_grades = final_grades_card.no_grades_heading?
                  it ("show a 'no grades' message on the #{semester_name} page for UID #{uid}") { expect(shows_no_grades).to be true }

                end
              end
            end

          rescue => e
            logger.error e.message + "\n" + e.backtrace.join("\n")
          end
        end
      end

    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n ")
    ensure
      WebDriverUtils.quit_browser driver
    end
  end
end
