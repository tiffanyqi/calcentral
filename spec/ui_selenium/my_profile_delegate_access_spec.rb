describe 'Delegated access', :testui => true do

  if ENV['UI_TEST'] && Settings.ui_selenium.layer == 'local'

    include ClassLogger

    begin
      @driver = WebDriverUtils.launch_browser
      timeout = WebDriverUtils.page_load_timeout

      @splash_page = CalCentralPages::SplashPage.new @driver
      @basic_info_page = CalCentralPages::MyProfileBasicInfoCard.new @driver
      @delegate_access_page = CalCentralPages::MyProfileDelegateAccessCard.new @driver
      @status_api = ApiMyStatusPage.new @driver

      test_users = UserUtils.load_test_users.select { |user| user['delegatedAccess'] }
      test_users.each do |user|
        uid = user['uid']
        logger.info "Test UID is #{uid}"
        user_roles = user['delegatedAccess']['roles']

        begin
          @splash_page.load_page
          @splash_page.basic_auth uid
          @status_api.get_json @driver

          # Verify validity of test data to assist test maintenance

          is_student = @status_api.is_student?
          it ("test data thinks UID #{uid} is a student but the status API disagrees") { fail } if user_roles['student'] && !is_student

          is_concurrent = @status_api.is_concurrent_enroll_student?
          it ("test data thinks UID #{uid} is a concurrent enrollment student but the status API disagrees") { fail } if user_roles['concurrentEnrollment'] && !is_concurrent

          is_ex_student = @status_api.is_ex_student?
          it ("test data thinks UID #{uid} is an ex-student but the status API disagrees") { fail } if user_roles['exStudent'] && !is_ex_student

          is_applicant = @status_api.is_applicant?
          it ("test data thinks UID #{uid} is an ex-student but the status API disagrees") { fail } if user_roles['applicant'] && !is_applicant

          is_faculty = @status_api.is_faculty?
          it ("test data thinks UID #{uid} is faculty but the status API disagrees") { fail } if user_roles['faculty'] && !is_faculty

          is_staff = @status_api.is_staff?
          it ("test data thinks UID #{uid} is staff but the status API disagrees") { fail } if user_roles['staff'] && !is_staff

          is_advisor = @status_api.is_advisor?
          it ("test data thinks UID #{uid} is an advisor but the status API disagrees") { fail } if user_roles['advisor'] && !is_advisor

          is_delegate = @status_api.is_delegate?
          it ("test data thinks UID #{uid} is a delegate but the status API disagrees") { fail } if user_roles['delegate'] && !is_delegate

          @basic_info_page.load_page
          @basic_info_page.sidebar_element.when_visible timeout
          has_delegate_access = @basic_info_page.delegate_access_link?

          if user_roles['student']

            it ("offers a 'Delegate Access' Profile menu option to UID #{uid}") { expect(has_delegate_access).to be true }

            @basic_info_page.click_delegate_access @driver
            @delegate_access_page.manage_delegates_msg_element.when_visible timeout

            has_manage_delegates_link = @delegate_access_page.manage_delegates_link?
            it ("offers link to Manage Delegates for UID #{uid}") { expect(has_manage_delegates_link).to be true }

            has_share_bcal_link = WebDriverUtils.verify_external_link(@driver, @delegate_access_page.bcal_link_element, 'Share your calendar with someone - Calendar Help')
            it ("offers a link to instructions for sharing bCal to UID #{uid}") { expect(has_share_bcal_link).to be true }

          else

            it ("offers no Profile menu Delegate Access option to UID #{uid}") { (has_delegate_access).to be false }

            @delegate_access_page.load_page
            @delegate_access_page.wait_until(timeout) { @delegate_access_page.title == 'Error | CalCentral' }

            hits_delegate_404 = @delegate_access_page.not_found?
            it ("prevents UID #{uid} from hitting the Delegate Access page directly") { expect(hits_delegate_404).to be true }

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
