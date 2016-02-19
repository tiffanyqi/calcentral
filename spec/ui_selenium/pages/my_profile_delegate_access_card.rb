module CalCentralPages

  include PageObject
  include ClassLogger

  class MyProfileDelegateAccessCard < MyProfilePage

    link(:manage_delegates_link, :text => 'Manage Delegates')
    paragraph(:manage_delegates_msg, :xpath => '//p[contains(.,"To create a new delegate or change the privileges of an existing one, click the link above.")]')
    link(:bcal_link, :xpath => '//a[contains(.,"bCal instructions")]')

    def load_page
      navigate_to "#{WebDriverUtils.base_url}/profile/delegate"
    end

  end
end
