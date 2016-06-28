module CalCentralPages

  module MyFinancesPages

    class MyFinancesDetailsPage

      include PageObject
      include CalCentralPages
      include MyFinancesPages
      include ClassLogger

      wait_for_expected_title('My Finances | CalCentral', WebDriverUtils.page_load_timeout)
      h1(:page_heading, :xpath => '//h1[contains(.,"Details"]')
      div(:activity_spinner, :xpath => '//h2[text()="Activity"]/../following-sibling::div[@class="cc-spinner"]')

      link(:sort_by_date, :xpath => '//th[@data-ng-click="changeSorting(\'transDate\')"]')
      link(:sort_by_descrip, :xpath => '//th[@data-ng-click="changeSorting(\'transDesc\')"]')
      link(:sort_by_amount, :xpath => '//th[@data-ng-click="changeSorting(\'transBalanceAmountFloat\')"]')
      link(:sort_by_trans_type, :xpath => '//th[@data-ng-click="changeSorting(\'transType\')"]')
      link(:sort_by_due_now, :xpath => '//th[@data-ng-click="changeSorting(\'isDueNow\')"]')
      image(:sort_descending, :xpath => '//i[@class="fa fa-chevron-down"]')
      image(:sort_ascending, :xpath => '//i[@class="fa fa-chevron-up"]')

      # The following are elements from the first transaction in the UI
      span(:trans_date, :xpath => '//span[@data-ng-bind="item.transDate | date:\'MM/dd/yy\'"]')
      div(:trans_desc, :xpath => '//div[@data-ng-bind="item.transDesc"]')
      td(:trans_amt, :xpath => '//td[@data-cc-amount-directive="item.transBalanceAmount"]')
      span(:trans_type, :xpath => '//span[@data-ng-bind="item.transType"]')
      image(:trans_due_future_icon, :xpath => '//i[@class="fa ng-scope fa-arrow-right"]')
      image(:trans_due_now_icon, :xpath => '//i[@class="fa ng-scope fa-exclamation"]')
      image(:trans_due_past_icon, :xpath => '//i[@class="fa ng-scope fa-exclamation-circle cc-icon-red"]')
      div(:trans_id, :xpath => '//div[@data-ng-if="item.transId"]')
      div(:trans_orig_amt, :xpath => '//div[@data-ng-if="item.originalAmount"]')
      div(:trans_due_date, :xpath => '//div[@data-ng-if="item.transDueDateShow && !(item.transStatus === \'Closed\' && item.transType === \'Refund\')"]')
      div(:trans_dept, :xpath => '//div[@data-ng-if="item.transDept"]')
      div(:trans_term, :xpath => '//div[@data-ng-if="item.transTerm"]')
      div(:trans_disburse_date, :xpath => '//div[@data-ng-if="item.transPotentialDisbursementDate"]')
      div(:trans_ref_method, :xpath => '//div[@data-ng-if="item.transPaymentMethod"]')
      div(:trans_ref_date, :xpath => '//div[@data-ng-if="item.transPaymentLastActionDate"]')
      div(:trans_ref_action, :xpath => '//div[@data-ng-if="item.transPaymentLastAction"]')
      div(:trans_ref_void, :xpath => '//div[@data-ng-if="item.transPaymentVoidDate"]')
      div(:trans_unapplied, :xpath => '//div[@data-ng-if="item.transStatus === \'Unapplied\' && item.transType === \'Award\'"]')

      span(:last_update_date, :xpath => '//span[@data-ng-bind="myfinances.summary.lastUpdateDate | date:\'MM/dd/yy\'"]')

      def load_page
        logger.info 'Loading My Finances details page'
        sleep 1
        navigate_to "#{WebDriverUtils.base_url}/finances/details"
        activity_spinner_element.when_not_visible if activity_spinner_element.visible?
      end

      def load_summary
        tries ||= 5
        load_page
        min_amt_due_element.when_visible
      rescue
        retry unless (tries -= 1).zero?
      end

      def visible_transactions_sum_str
        sum = visible_transaction_amts_str.inject(BigDecimal.new('0')) { |acc, amt| acc + BigDecimal.new(amt) }
        (sprintf '%.2f', sum).to_s
      end

      # TRANSACTION SORTING

      def sort_by_date_asc
        logger.info 'Sorting by date ascending'
        sort_by_date
        sort_by_date if sort_descending?
      end

      def sort_by_date_desc
        logger.info 'Sorting by date descending'
        sort_by_date
        sort_by_date if sort_ascending?
      end

      def sort_by_descrip_asc
        logger.info 'Sorting by description ascending'
        sort_by_descrip
        sort_by_descrip if sort_descending?
      end

      def sort_by_descrip_desc
        logger.info 'Sorting by description descending'
        sort_by_descrip
        sort_by_descrip if sort_ascending?
      end

      def sort_by_amount_asc
        logger.info 'Sorting by amount ascending'
        sort_by_amount
        sort_by_amount if sort_descending?
      end

      def sort_by_amount_desc
        logger.info 'Sorting by amount descending'
        sort_by_amount
        sort_by_amount if sort_ascending?
      end

      def sort_by_trans_type_asc
        logger.info 'Sorting by transaction type ascending'
        sort_by_trans_type
        sort_by_trans_type if sort_descending?
      end

      def sort_by_trans_type_desc
        logger.info 'Sorting by transaction type descending'
        sort_by_trans_type
        sort_by_trans_type if sort_ascending?
      end

    end
  end
end
