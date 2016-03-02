module CalCentralPages

  class MyProfileInfoDisclosureCard

    include PageObject
    include CalCentralPages
    include ClassLogger

    def load_page
      logger.debug 'Loading profile information disclosure page'
      navigate_to "#{WebDriverUtils.base_url}/profile/information-disclosure"
    end

  end

end
