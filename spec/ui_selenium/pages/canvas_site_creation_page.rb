module CalCentralPages

  class CanvasSiteCreationPage

    include PageObject
    include CalCentralPages
    include ClassLogger

    h2(:page_heading, :xpath => '//h2[text()="Create a Site"]')

    link(:create_course_site_link, :text => 'Create a Course Site')
    paragraph(:course_sites_text, :xpath => '//p[contains(text(),"Set up course sites to communicate with and manage the work of students enrolled in your classes.")]')
    paragraph(:no_course_sites_text, :xpath => '//p[contains(text(),"It appears that you do not have permissions to create a Course Site in the current or upcoming terms.")]')
    link(:bcourses_support_link, :xpath => '//a[contains(text(),"bCourses support")]')

    link(:create_project_site_link, :text => 'Create a Project Site')
    paragraph(:projects_sites_text, :xpath => '//p[contains(text(),"Share files and collaborate with your project or teaching team. Projects are best suited for instructors and GSIs who already use bCourses for their courses.")]')
    link(:projects_learn_more_link, :xpath => '//a[contains(text(), "Learn more about your online collaboration options.")]')

    def load_page
      navigate_to "#{WebDriverUtils.base_url}/canvas/embedded/site_creation"
      page_heading_element.when_visible WebDriverUtils.page_load_timeout
    end

    def click_create_course_site(course_site_page)
      WebDriverUtils.wait_for_element_and_click create_course_site_link_element
      course_site_page.page_heading_element.when_visible WebDriverUtils.page_load_timeout
    end

    def click_create_project_site
      WebDriverUtils.wait_for_element_and_click create_project_site_link_element
    end

    def choose_course_site(driver, course, instructor, canvas, create_course_site)
      create_site_workflow = course['workflow']
      canvas.stop_masquerading driver if canvas.stop_masquerading_link?
      if create_site_workflow == 'uid' || create_site_workflow == 'ccn'
        canvas.load_create_site_tool(driver, UserUtils.canvas_id, WebDriverUtils.canvas_create_site_id)
        click_create_course_site create_course_site
      else
        canvas.masquerade_as instructor['canvasId']
        canvas.load_create_site_tool(driver, instructor['canvasId'], WebDriverUtils.canvas_create_site_id)
        click_create_course_site create_course_site
      end
    end

  end
end
