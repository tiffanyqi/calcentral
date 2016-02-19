module CalCentralPages

  class MyProfilePage

    include PageObject
    include CalCentralPages
    include ClassLogger

    div(:sidebar, :id => 'cc-local-navigation')
    link(:basic_info_link, :text => 'Basic Information')
    link(:contact_info_link, :text => 'Contact Information')
    link(:emergency_contact_link, :text => 'Emergency Contact')
    link(:demographic_info_link, :text => 'Demographic Information')
    link(:delegate_access_link, :text => 'Delegate Access')
    link(:title_iv_release_link, :text => 'Title IV Release')
    link(:languages_link, :text => 'Languages')
    link(:work_experience_link, :text => 'Work Experience')
    link(:bconnected_link, :text => 'bConnected')
    link(:honors_and_awards_link, :text => 'Academic Honors and Awards')

    def click_contact_info
      WebDriverUtils.wait_for_element_and_click contact_info_link_element
    end

    def click_delegate_access(driver)
      WebDriverUtils.wait_for_element_and_click delegate_access_link_element
      CalCentralPages::MyProfileDelegateAccessCard.new driver
    end

    def click_bconnected(driver)
      WebDriverUtils.wait_for_element_and_click bconnected_link_element
      CalCentralPages::MyProfileBconnectedCard.new driver
    end

  end
end
