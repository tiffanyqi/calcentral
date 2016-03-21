module CalCentralPages

  class MyToolboxPage

    include PageObject
    include CalCentralPages
    include ClassLogger

    def load_page
      navigate_to "#{WebDriverUtils.base_url}/toolbox"
    end

    # VIEW AS

    text_area(:view_as_input, :id => 'cc-toolbox-view-as-uid')
    button(:view_as_submit_button, :xpath => '//button[text()="Submit"]')

    div(:saved_users, :xpath => '//div[@class="cc-toolbox-user-section ng-scope"][1]')
    button(:clear_saved_users_button, :xpath => '//strong[text()="Saved Users"]/following-sibling::button[@data-ng-click="block.clearAllUsers()"]')
    div(:saved_user_view_as_button, :xpath => '//strong[text()="Saved Users"]/following-sibling::div//button[@data-ng-click="admin.updateIDField(user.ldap_uid)"]')
    span(:saved_user_sid, :xpath => '//strong[text()="Saved Users"]/following-sibling::div//span[contains(@data-ng-bind,"user.student_id")]')
    span(:saved_user_name, :xpath => '//strong[text()="Saved Users"]/following-sibling::div//span[@data-ng-bind="user.first_name"]')
    button(:saved_user_delete_button, :xpath => '//button[@data-ng-click="block.clearUser(user)"]')

    div(:recent_users, :xpath => '//div[@class="cc-toolbox-user-section ng-scope"][2]')
    button(:clear_recent_users_button, :xpath => '//strong[text()="Recent Users"]/following-sibling::button[@data-ng-click="block.clearAllUsers()"]')
    div(:recent_user_view_as_button, :xpath => '//strong[text()="Recent Users"]/following-sibling::div//button[@data-ng-click="admin.updateIDField(user.ldap_uid)"]')
    span(:recent_user_sid, :xpath => '//strong[text()="Recent Users"]/following-sibling::div//span[contains(@data-ng-bind,"user.student_id")]')
    span(:recent_user_name, :xpath => '//strong[text()="Recent Users"]/following-sibling::div//span[@data-ng-bind="user.first_name"]')
    button(:recent_user_save_button, :xpath => '//button[@data-ng-click="block.storeUser(user)"]')

    def view_as_user(id)
      WebDriverUtils.wait_for_element_and_type(view_as_input_element, id)
      view_as_submit_button
    end

    def clear_all_saved_users
      WebDriverUtils.wait_for_element_and_click clear_saved_users_button_element if clear_saved_users_button?
    end

    def view_as_first_saved_user
      WebDriverUtils.wait_for_page_and_click saved_user_view_as_button_element
    end

    def clear_all_recent_users
      WebDriverUtils.wait_for_element_and_click clear_recent_users_button_element if clear_recent_users_button?
    end

    def view_as_first_recent_user
      WebDriverUtils.wait_for_page_and_click recent_user_view_as_button_element
    end

    def save_first_recent_user
      WebDriverUtils.wait_for_page_and_click recent_user_save_button_element
    end

    # UID/SID LOOKUP

    text_area(:lookup_input, :id => 'cc-toolbox-id')
    button(:lookup_button, :xpath => '//button[text()="Look Up"]')
    table(:lookup_results_table, :xpath => '//form[@data-ng-submit="admin.lookupUser()"]//table')

    def look_up_user(id)
      WebDriverUtils.wait_for_element_and_type(lookup_input_element, id)
      lookup_button
    end

    # DELEGATED ACCESS

    div(:delegate_msg_heading, :xpath => '//h3[text()="You are a Delegate"]')
    paragraph(:delegate_msg, :xpath => '//p[contains(.,"A student (your Delegator) has delegated privileges to you.")]')
    button(:show_more, :xpath => '//button[contains(.,"Show more")]')
    button(:show_less, :xpath => '//button[contains(.,"Show less")]')
    paragraph(:delegate_msg_expanded, :xpath => '//p[contains(.,"To view information for a student")]')
    elements(:delegate_student, :button, :xpath => '//span[@data-ng-bind="student.fullName"]/parent::button[@data-ng-if="student.delegateAccess && student.uid"]')
    elements(:delegate_student_static, :div, :xpath => '//div[@data-ng-if="!student.delegateAccess || !student.uid"]')
    div(:no_students_msg, :xpath => '//strong[contains(text(),"You are not currently a delegate for any students.")]')
    link(:subscribe_to_calendar, :xpath => '//a[contains(.,"Subscribe to the Academic Calendar")]')
    link(:grad_div_deadlines, :xpath => '//a[contains(.,"Graduate Division Degree Deadlines")]')
    link(:cal_parents, :xpath => '//a[contains(.,"CalParents")]')
    link(:important_dates, :xpath => '//a[contains(.,"Important Dates for Parents")]')
    link(:visiting_campus, :xpath => '//a[contains(.,"Visiting the Campus")]')
    link(:jobs_and_careers, :xpath => '//a[contains(.,"Jobs & Careers")]')
    link(:housing, :xpath => '//a[contains(.,"Housing")]')
    link(:financial_info, :xpath => '//a[contains(.,"Financial Information")]')
    link(:academics, :xpath => '//a[contains(@href,"http://calparents.berkeley.edu/academics/")]')
    link(:academic_calendar, :xpath => '//a[contains(.,"Academic Calendar")]')
    link(:news_center, :xpath => '//a[contains(.,"UC Berkeley NewsCenter")]')
    link(:berkeley_news, :xpath => '//a[contains(.,"Berkeley in the News")]')
    link(:daily_cal, :xpath => '//a[contains(.,"The Daily Californian")]')

    def all_delegator_names
      wait_until(WebDriverUtils.page_event_timeout) { delegate_student_elements.any? }
      names = []
      delegate_student_elements.each { |student| names << student.text }
      delegate_student_static_elements.each { |student| names << student.text }
      names.sort!
    end

    def delegator_link(name)
      wait_until(WebDriverUtils.page_event_timeout) { delegate_student_elements.any? }
      delegate_student_elements.find { |element| element.text.include? name }
    end

    def delegate_view_as(name)
      # End any pre-existing view-as session before starting new one
      delegate_stop_viewing
      WebDriverUtils.wait_for_element_and_click delegator_link(name)
      delegate_stop_viewing_as_element.when_visible WebDriverUtils.page_load_timeout
    end

    def show_more
      WebDriverUtils.wait_for_element_and_click show_more_element
    end

    def show_less
      WebDriverUtils.wait_for_element_and_click show_less_element
    end

  end
end
