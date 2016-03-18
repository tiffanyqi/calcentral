module CalCentralPages

  class MyProfilePage

    include PageObject
    include CalCentralPages
    include ClassLogger

    # Profile
    link(:basic_info_link, :text => 'Basic Information')
    link(:contact_info_link, :text => 'Contact Information')
    link(:emergency_contact_link, :text => 'Emergency Contact')
    link(:demographic_info_link, :text => 'Demographic Information')

    # Privacy and Permissions
    link(:delegate_access_link, :text => 'Delegate Access')
    link(:information_disclosure_link, :text => 'Information Disclosure')
    link(:title_iv_release_link, :text => 'Title IV Release')

    # Credentials
    link(:languages_link, :text => 'Languages')
    link(:work_experience_link, :text => 'Work Experience')
    link(:honors_and_awards_link, :text => 'Academic Honors and Awards')

    # Alerts and Notifications
    link(:bconnected_link, :text => 'bConnected')

    def click_contact_info
      WebDriverUtils.wait_for_element_and_click contact_info_link_element
    end

    def click_bconnected(driver)
      WebDriverUtils.wait_for_element_and_click bconnected_link_element
      CalCentralPages::MyProfileBconnectedCard.new driver
    end

  end
end
