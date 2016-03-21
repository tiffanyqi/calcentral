module CalCentralPages

  class MyProfileDemographicCard < MyProfilePage

    include PageObject
    include CalCentralPages
    include ClassLogger

    def load_page
      logger.debug 'Loading profile demographics page'
      navigate_to "#{WebDriverUtils.base_url}/profile/demographic"
    end

  end
end
