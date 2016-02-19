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
    button(:clear_saved_users_button, :xpath => '//strong[text()="Saved Users"]/following-sibling::button[text()="clear all"]')
    elements(:saved_user_view_as_button, :div, :xpath => '//strong[text()="Saved Users"]/following-sibling::ul//button[@data-ng-click="admin.updateIDField(user.ldap_uid)"]')
    elements(:saved_user_delete_button, :button, :xpath => '//button[text()="delete"]')
    div(:recent_users, :xpath => '//div[@class="cc-toolbox-user-section ng-scope"][2]')
    button(:clear_recent_users_button, :xpath => '//strong[text()="Recent Users"]/following-sibling::button[text()="clear all"]')
    elements(:recent_user_view_as_button, :div, :xpath => '//strong[text()="Recent Users"]/following-sibling::ul//button[@data-ng-click="admin.updateIDField(user.ldap_uid)"]')
    elements(:recent_user_save_button, :button, :xpath => '//button[text()="save"]')

    def view_as_user(id)
      WebDriverUtils.wait_for_element_and_type(view_as_input_element, id)
      view_as_submit_button
    end

    def clear_all_saved_users
      saved_users_element.when_present(timeout=WebDriverUtils.page_load_timeout)
      WebDriverUtils.wait_for_element_and_click clear_saved_users_button_element if clear_saved_users_button?
    end

    def view_as_first_saved_user
      wait_until(timeout=WebDriverUtils.page_load_timeout) { saved_user_view_as_button_elements.any? }
      saved_user_view_as_button_elements[0].click
    end

    def clear_all_recent_users
      recent_users_element.when_present(timeout=WebDriverUtils.page_load_timeout)
      clear_recent_users_button if clear_recent_users_button?
    end

    def view_as_first_recent_user
      wait_until(timeout=WebDriverUtils.page_load_timeout) { recent_user_view_as_button_elements.any? }
      recent_user_view_as_button_elements[0].click
    end

    def save_first_recent_user
      wait_until(timeout=WebDriverUtils.page_load_timeout) { recent_user_save_button_elements.any? }
      recent_user_save_button_elements[0].click
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

    # TODO div(:delegate_msg_heading, :xpath => '//h3[text()="You are a Delegate"]')
    # TODO div(:delegate_instructions, :xpath => '//div[contains(.,"")]')
    # TODO button(:show_more, :xpath => '//button[contains(.,"Show More")]')
    # TODO button(:show_less, :xpath => '//button[contains(.,"Show Less")]')
    # TODO elements(:delegate_student, :button, :xpath => '//button[]')
    # TODO elements(:academic_date, ?, ?)
    # TODO link(:subscribe_to_calendar, :xpath => '//a[contains(.,"Subscribe to the Academic Calendar")]')
    # TODO link(:grad_div_deadlines, :xpath => '//a[contains(.,"Graduate Division Degree Deadlines")]')
    # TODO link(:cal_parents, :xpath => '//a[contains(.,"CalParents")]')
    # TODO link(:academic_calendar, :xpath => '//a[contains(.,"Academic Calendar")]')
    # TODO link(:news_center, :xpath => '//a[contains(.,"UC Berkeley NewsCenter")]')
    # TODO link(:berkeley_news, :xpath => '//a[contains(.,"Berkeley in the News")]')
    # TODO link(:daily_cal, :xpath => '//a[contains(.,"The Daily Californian")]')

    def show_more
      WebDriverUtils.wait_for_element_and_click show_more_element
    end

    def show_less
      WebDriverUtils.wait_for_element_and_click show_less_element
    end

  end
end
