module CalCentralPages

  include PageObject
  include ClassLogger

  class MyProfileDelegateAccessCard < MyProfilePage

    link(:manage_delegates_link, :text => 'Create or manage delegates')
    link(:bcal_link, :xpath => '//a[contains(.,"bCal instructions")]')

    def load_page
      logger.debug 'Loading profile delegate access page'
      navigate_to "#{WebDriverUtils.base_url}/profile/delegate"
    end

  end
end
