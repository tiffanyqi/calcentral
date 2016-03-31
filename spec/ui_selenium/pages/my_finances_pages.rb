module CalCentralPages

  module MyFinancesPages

    include PageObject
    include CalCentralPages
    include ClassLogger

    wait_for_expected_title('My Finances | CalCentral', WebDriverUtils.page_load_timeout)
    h1(:page_heading, :xpath => '//h1[text()="My Finances"]')

    # BILLING SUMMARY CARD
    h2(:billing_summary_heading, :xpath => '//h2[text()="Billing Summary"]')
    link(:details_link, :text => 'Details')
    div(:billing_summary_spinner, :xpath => '//h2[contains(.,"Billing Summary")]/../following-sibling::div[@class="cc-spinner"]')
    paragraph(:no_cars_data_msg, :xpath => '//p[@data-ng-if="myfinancesError"]')
    unordered_list(:billing_summary_list, :xpath => '//ul[@data-ng-show="myfinances.summary"]')
    div(:dpp_balance_element, :xpath => '//div[@data-cc-amount-directive="myfinances.summary.dppBalance"]')
    div(:dpp_normal_install_element, :xpath => '//div[@data-cc-amount-directive="myfinances.summary.dppNormalInstallmentAmount"]')
    div(:dpp_text, :xpath => '//div[contains(text(),"1: Reflected in charges with DPP")]')
    label(:amt_due_now_label, :xpath => '//strong[@data-cc-amount-directive="myfinances.summary.minimumAmountDue"]/../../preceding-sibling::div/strong[1]')
    div(:amt_due_now_element, :xpath => '//div[@class="cc-page-myfinances-amount"]/strong[@data-cc-amount-directive="myfinances.summary.minimumAmountDue"]')
    span(:past_due_amt_element, :xpath => '//span[@data-cc-amount-directive="myfinances.summary.totalPastDueAmount"]')
    div(:charges_not_due_element, :xpath => '//div[@data-cc-amount-directive="myfinances.summary.futureActivity"]')
    div(:account_balance_element, :xpath => '//div[@data-cc-amount-directive="myfinances.summary.accountBalance"]')
    link(:toggle_last_statement_bal, :xpath => '//div[@data-ng-click="api.widget.toggleShow($event, null, myfinances, \'My Finances - Summary\')"]')
    div(:last_statement_bal_element, :xpath => '//div[@data-cc-amount-directive="myfinances.summary.lastStatementBalance"]')
    link(:view_statements_link, :xpath => '//a[contains(text(),"View Statements")]')
    link(:make_payment_link, :xpath => '//a[@href="http://studentbilling.berkeley.edu/carsPaymentOptions.htm"]')

    # FINANCIAL AID SUMMARY CARD
    div(:finaid_content, :xpath => '//div[@data-ng-if="!finaidSummaryInfo.errored"]')
    div(:finaid_summary_info, :xpath => '//div[@data-onload="netCostInfo.card = \'summary\'"]')
    div(:finaid_summary_label, :class => 'cc-widget-finaid-summary-label')
    div(:finaid_summary_message, :class => 'cc-widget-finaid-summary-message-title')
    div(:no_finaid_message, :xpath => '//div[contains(.,"You do not currently have any Financial Aid information ready to view.")]')

    span(:finaid_single_year, :xpath => '//span[@data-ng-bind="selected.finaidYear.name"]')
    select_list(:finaid_multi_year_select, :id => 'cc-widget-finaid-summary-select-year')
    span(:finaid_semesters, :xpath => '//span[@data-ng-bind="selected.finaidYear.availableSemesters | andFilter"]')

    div(:net_cost_section, :class => 'cc-widget-finaid-summary-netcost-summary')
    div(:finaid_cost_of_attend, :xpath => '//div[@data-ng-if="finaidSummaryData.netCost"]//span[text()="Estimated Cost of Attendance"]/../following-sibling::div')
    div(:finaid_gift_aid, :xpath => '//div[@data-ng-if="finaidSummaryData.netCost"]//span[text()="Gift Aid"]/../following-sibling::div')
    div(:finaid_net_cost, :xpath => '//div[@data-ng-if="finaidSummaryData.netCost"]//span[text()="Net Cost"]/../following-sibling::div')

    div(:finaid_funding_offered_ttl, :xpath => '//div[@data-ng-if="finaidSummaryData.fundingOffered"]//span[text()="Funding Offered"]/../following-sibling::div')
    div(:finaid_funding_offered_toggle, :xpath => '//div[@data-ng-if="finaidSummaryData.fundingOffered"]/div')
    div(:finaid_funding_gift_aid, :xpath => '//div[@data-ng-if="showFundingOfferedDetails"]//span[text()="Gift Aid"]/../following-sibling::div')
    div(:finaid_funding_grants, :xpath => '//div[@data-ng-if="showFundingOfferedDetails"]//span[text()="Grants and Scholarships"]/../following-sibling::div')
    div(:finaid_funding_waivers, :xpath => '//div[@data-ng-if="showFundingOfferedDetails"]//span[text()="Fee Waivers"]/../following-sibling::div')
    div(:finaid_funding_other, :xpath => '//div[@data-ng-if="showFundingOfferedDetails"]//span[text()="Other Funding"]/../following-sibling::div')
    div(:finaid_funding_loans, :xpath => '//div[@data-ng-if="showFundingOfferedDetails"]//span[text()="Loans"]/../following-sibling::div')
    div(:finaid_funding_work_study, :xpath => '//div[@data-ng-if="showFundingOfferedDetails"]//span[text()="Work Study"]/../following-sibling::div')

    link(:finaid_t_and_c_link, :text => 'Complete Terms and Conditions')
    link(:finaid_title_iv_link, :text => 'Complete Title IV')
    link(:finaid_details_link, :xpath => '//h2[contains(.,"Financial Aid and Scholarships")]/following-sibling::a')
    link(:awards_link, :xpath => '//div[@data-ng-controller="FinaidSummaryController"]//a[contains(.,"View Awards")]')
    link(:shopping_sheet_link, :xpath => '//a[contains(.,"Shopping Sheet")]')

    link(:learn_more_link, :xpath => '//a[contains(.,"Learn more about Financial Aid")]')
    link(:faso_link, :xpath => '//div[@data-ng-controller="FinaidSummaryController"]//a[contains(.,"Financial Aid & Scholarships")]')
    link(:csu_link, :xpath => '//div[@data-ng-controller="FinaidSummaryController"]//a[contains(.,"Cal Student Central")]')

    # BILLING AND PAYMENTS

    def show_last_statement_bal
      unless last_statement_bal_element_element.visible?
        toggle_last_statement_bal
        last_statement_bal_element_element.when_visible(timeout=WebDriverUtils.page_event_timeout)
      end
    end

    def hide_last_statement_bal
      if last_statement_bal_element_element.visible?
        toggle_last_statement_bal
        last_statement_bal_element_element.when_not_visible(timeout=WebDriverUtils.page_event_timeout)
      end
    end

    def click_billing_details_link
      details_link
      activity_heading_element.when_visible(timeout=WebDriverUtils.page_load_timeout)
    end

    def account_balance
      account_balance_element_element.when_visible(timeout=WebDriverUtils.page_load_timeout)
      account_balance_element.delete('$, ')
    end

    def last_statement_balance
      last_statement_bal_element_element.when_visible(timeout=WebDriverUtils.page_load_timeout)
      last_statement_bal_element.delete('$, ')
    end

    def amt_due_now
      amt_due_now_element_element.when_visible(timeout=WebDriverUtils.page_load_timeout)
      amt_due_now_element.delete('$, ')
    end

    def past_due_amt
      past_due_amt_element_element.when_visible(timeout=WebDriverUtils.page_load_timeout)
      past_due_amt_element.delete('$, ')
    end

    def charges_not_due
      charges_not_due_element_element.when_visible(timeout=WebDriverUtils.page_load_timeout)
      charges_not_due_element.delete('$, ')
    end

    def dpp_balance
      dpp_balance_element_element.when_visible(timeout=WebDriverUtils.page_load_timeout)
      dpp_balance_element.delete('$, ')
    end

    def dpp_normal_install
      dpp_normal_install_element_element.when_visible(timeout=WebDriverUtils.page_load_timeout)
      dpp_normal_install_element.delete('$, ')
    end

    # FINANCIAL AID - CS CARD

    def click_fin_aid_details_link
      logger.debug 'Clicking link to FinAid Details'
      details_link
      activity_heading_element.when_visible WebDriverUtils.page_load_timeout
    end

    def select_fin_aid_year(available_years, desired_year)
      logger.debug "Viewing FinAid for #{desired_year}"
      finaid_summary_label_element.when_visible WebDriverUtils.page_load_timeout
      WebDriverUtils.wait_for_element_and_select(finaid_multi_year_select_element, desired_year) unless available_years.length == 1
      wait_until(WebDriverUtils.page_event_timeout) { finaid_details_link_element.attribute('href').include? desired_year }
    end

    def click_t_and_c_link(finaid_page)
      logger.info 'Clicking T&C link'
      WebDriverUtils.wait_for_element_and_click finaid_t_and_c_link_element
      finaid_page.t_and_c_heading_element.when_visible WebDriverUtils.page_load_timeout
    end

    def click_title_iv_link(finaid_page)
      logger.info 'Clicking Title IV link'
      WebDriverUtils.wait_for_element_and_click finaid_title_iv_link_element
      finaid_page.title_iv_heading_element.when_visible WebDriverUtils.page_load_timeout
    end

  end
end
