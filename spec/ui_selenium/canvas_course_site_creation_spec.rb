describe 'bCourses course site creation', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      @driver = WebDriverUtils.launch_browser
      @splash_page = CalCentralPages::SplashPage.new @driver
      @cal_net_page = CalNetAuthPage.new @driver
      @status_api = ApiMyStatusPage.new @driver
      @academics_api = ApiMyAcademicsPage.new @driver
      @site_creation_page = CalCentralPages::CanvasSiteCreationPage.new @driver
      @create_course_site_page = CalCentralPages::CanvasCreateCourseSitePage.new @driver
      @canvas_page = CanvasPage.new @driver

      @canvas_page.log_in(@cal_net_page, UserUtils.canvas_username, UserUtils.canvas_password)

      test_courses = UserUtils.load_canvas_courses
      test_courses.each do |course|

        begin
          # Test data
          course_term = course['term']
          course_code = course['courseCode']
          instruction_formats = course['sectionFormatsInSite'].map { |format| format['label'] }
          test_id = Time.now.to_i.to_s
          instructor = course['teachers'].find { |teacher| teacher['testUser'] }

          logger.info "Creating a course site for #{course_code} in #{course_term} using the '#{course['workflow']}' workflow"

          @site_creation_page.choose_course_site(@driver, course, instructor, @canvas_page, @create_course_site_page)
          @create_course_site_page.search_for_course(course, instructor)
          @create_course_site_page.toggle_course_sections course

          expected_section_ids = course['sections'].map { |section| section['ccn'] }
          visible_section_ids = @create_course_site_page.course_section_ids(@driver, course_code)
          it ("offers all the expected sections for #{course_term} #{course_code}") { expect(visible_section_ids.sort!).to eql(expected_section_ids.sort!) }

          filtered_section_data = @create_course_site_page.sections_by_formats(@driver, course, instruction_formats)
          @create_course_site_page.select_sections filtered_section_data
          @create_course_site_page.click_next

          it ("shows the default site name #{course['courseTitle']}") {}
          it ("shows the default site abbreviation #{course['courseCode']}")

          @create_course_site_page.enter_site_titles(course_code, test_id)
          @create_course_site_page.click_create_site

          @canvas_page.wait_until(WebDriverUtils.canvas_update_timeout) { @canvas_page.current_url.include? "#{WebDriverUtils.canvas_base_url}/courses" }
          site_id = @canvas_page.current_url.delete "#{WebDriverUtils.canvas_base_url}/courses/"
          logger.info "Canvas course site ID is #{site_id}"

        rescue => e
          logger.error e.message + "\n" + e.backtrace.join("\n")
        end
      end
    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n")
    ensure
      WebDriverUtils.quit_browser(@driver)
    end
  end
end
