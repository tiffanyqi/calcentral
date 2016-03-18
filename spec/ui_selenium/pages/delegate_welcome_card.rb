module CalCentralPages

  class DelegateWelcomeCard

    include PageObject
    include CalCentralPages

    def load_page
      navigate_to "#{WebDriverUtils.base_url}/delegate_welcome"
    end

  end

end
