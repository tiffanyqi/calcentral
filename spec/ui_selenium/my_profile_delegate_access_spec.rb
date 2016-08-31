describe 'Delegated access', :testui => true do

  if ENV['UI_TEST'] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      @driver = WebDriverUtils.launch_browser
      timeout = WebDriverUtils.page_load_timeout

      @splash_page = CalCentralPages::SplashPage.new @driver
      @basic_info_page = CalCentralPages::MyProfileBasicInfoCard.new @driver
      @delegate_access_page = CalCentralPages::MyProfileDelegateAccessCard.new @driver
      @status_api = ApiMyStatusPage.new @driver

      test_users = UserUtils.load_test_users.select { |user| user['manageDelegates'] }
      test_users.each do |user|
        uid = user['uid']
        logger.info "Test UID is #{uid}"

        begin
          @splash_page.load_page
          @splash_page.basic_auth uid
          @status_api.get_json @driver

          is_student = @status_api.is_student?

          @basic_info_page.load_page
          @basic_info_page.sidebar_element.when_visible timeout
          has_delegate_access = @basic_info_page.delegate_access_link?

          if is_student

            it ("offers a 'Delegate Access' Profile menu option to UID #{uid}") { expect(has_delegate_access).to be true }

            has_manage_delegates_link = WebDriverUtils.verify_block do
              @basic_info_page.click_delegate_access @driver
              @delegate_access_page.manage_delegates_link_element.when_visible timeout
            end
            it ("offers link to Manage Delegates for UID #{uid}") { expect(has_manage_delegates_link).to be true }

            has_share_bcal_link = WebDriverUtils.verify_external_link(@driver, @delegate_access_page.bcal_link_element, 'Share your calendar with someone - Calendar Help')
            it ("offers a link to instructions for sharing bCal to UID #{uid}") { expect(has_share_bcal_link).to be true }

          else

            it ("offers no Profile menu Delegate Access option to UID #{uid}") { expect(has_delegate_access).to be false }

            hits_delegate_404 = WebDriverUtils.verify_block do
              @delegate_access_page.load_page
              @delegate_access_page.not_found_element.when_visible timeout
            end
            it ("prevents UID #{uid} from hitting the Delegate Access page directly") { expect(hits_delegate_404).to be true}

          end
        rescue => e
          logger.error e.message + "\n" + e.backtrace.join("\n")
          it ("test hit an unexpected error handling the UI for UID #{uid}") { fail }
        end
      end
    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n ")
    ensure
      WebDriverUtils.quit_browser(@driver)
    end
  end
end
