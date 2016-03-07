module CalCentralPages

  class MyToolboxPage

    include PageObject
    include CalCentralPages
    include ClassLogger

    # View As
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

    # UID/SID Lookup
    text_area(:lookup_input, :id => 'cc-toolbox-id')
    button(:lookup_button, :xpath => '//button[text()="Look Up"]')
    table(:lookup_results_table, :xpath => '//form[@data-ng-submit="admin.lookupUser()"]//table')

    def load_page
      navigate_to "#{WebDriverUtils.base_url}/toolbox"
    end

    # VIEW-AS

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

    # LOOK UP USER

    def look_up_user(id)
      WebDriverUtils.wait_for_element_and_type(lookup_input_element, id)
      lookup_button
    end

  end

end