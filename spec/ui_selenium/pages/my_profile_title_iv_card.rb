module CalCentralPages

  class MyProfileTitleIVCard < MyProfilePage

    include PageObject
    include ClassLogger

    checkbox(:authorize_cbx, :id => 'cc-page-widget-profile-title4-check')
    span(:authorized_msg, :xpath => '//span[@data-ng-if="title4.isApproved"]')
    span(:non_authorized_msg, :xpath => '//span[@data-ng-if="!title4.isApproved"]')
    button(:show_more, :xpath => '//button[contains(.,"Show more")]')
    button(:show_less, :xpath => '//button[contains(.,"Show less")]')
    div(:expanded_content, :xpath => '//div[@data-ng-if="title4.showMessage"]')
    div(:authorized_msg_long, :xpath => '//div[@data-ng-if="title4.isApproved"]')
    div(:non_authorized_msg_long, :xpath => '//div[@data-ng-if="title4.isApproved === false"]')

    def authorize_title_iv
      authorize_cbx_element.when_visible timeout=WebDriverUtils.page_event_timeout
      check_authorize_cbx
      wait_until(timeout) { authorized_msg_element.visible? }
    end

    def revoke_title_iv
      authorize_cbx_element.when_visible timeout=WebDriverUtils.page_event_timeout
      uncheck_authorize_cbx
      wait_until(timeout) { non_authorized_msg_element.visible? }
    end

    def show_more
      WebDriverUtils.wait_for_element_and_click show_more_element
      expanded_content_element.when_visible WebDriverUtils.page_event_timeout
    end

    def show_less
      WebDriverUtils.wait_for_element_and_click show_less_element
      expanded_content_element.when_not_visible WebDriverUtils.page_event_timeout
    end

  end
end
