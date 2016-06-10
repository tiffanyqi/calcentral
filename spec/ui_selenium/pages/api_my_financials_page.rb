class ApiMyFinancialsPage

  include PageObject
  include ClassLogger

  def get_json(driver)
    logger.info 'Parsing JSON from /api/my/financials'
    navigate_to "#{WebDriverUtils.base_url}/api/my/financials"
    @parsed = JSON.parse driver.find_element(:xpath, '//pre').text
  end

  def has_cars_data?
    ![400, 404].include? @parsed['statusCode']
  end

  # ACCOUNT SUMMARY

  def summary
    @parsed['summary']
  end

  def account_balance
    summary['accountBalance']
  end

  def min_amt_due
    summary['minimumAmountDue']
  end

  def total_current_balance
    summary['totalCurrentBalance']
  end

  def past_due_amt
    summary['totalPastDueAmount']
  end

  def future_activity
    summary['futureActivity']
  end

  def is_on_dpp?
    summary['isOnDPP']
  end

  def is_dpp_past_due?
    summary['isDppPastDue']
  end

  def dpp_balance
    summary['dppBalance']
  end

  def dpp_norm_install_amt
    summary['dppNormalInstallmentAmount']
  end

  def last_statement_balance
    summary['lastStatementBalance']
  end

  # TRANSACTIONS

  def all_transactions
    @parsed['activity']
  end

  def trans_amt(item)
    item['transAmount']
  end

  def trans_balance(item)
    item['transBalance']
  end

  def trans_date(item)
    item['transDate']
  end

  def trans_date_as_date(item)
    Date.parse trans_date(item)
  end

  def trans_dept(item)
    item['transDept']
  end

  def trans_dept_url(item)
    item['transDeptUrl']
  end

  def trans_desc(item)
    item['transDesc']
  end

  def trans_due_date(item)
    item['transDueDate']
  end

  def trans_id(item)
    item['transId']
  end

  def trans_status(item)
    item['transStatus']
  end

  def trans_type(item)
    item['transType']
  end

  def trans_term(item)
    item['transTerm']
  end

  def trans_disburse_date(item)
    disburse_date = item['transPotentialDisbursementDate']
    disburse_date.blank? ? nil : Date.parse(disburse_date).strftime("%m/%d/%y")
  end

  def trans_disputed(item)
    item['transDisputedFlag']
  end

  def trans_refund_method(item)
    item['transPaymentMethod']
  end

  def trans_refund_last_action_date(item)
    item['transPaymentLastActionDate']
  end

  def trans_refund_last_action(item)
    item['transPaymentLastAction']
  end

  def trans_refund_void_date(item)
    item['transPaymentVoidDate']
  end

  def transactions_by_type(transactions, type)
    transactions.select { |item| trans_type(item) == type }
  end

  def transactions_by_id(transactions, id)
    transactions.select { |trans| trans_id(trans) == id }
  end

  def transactions_by_term(transactions, term)
    transactions.select { |item| trans_term(item) == term }
  end

  def transactions_by_date_range(start_date, end_date)
    all_transactions.select do |item|
      Date.strptime(start_date, '%m/%d/%Y') <= trans_date_as_date(item) && Date.strptime(end_date, '%m/%d/%Y') >= trans_date_as_date(item)
    end
  end

  def transactions_sum(transactions)
    transactions.inject(BigDecimal.new('0')) { |acc, bal| acc + BigDecimal.new(amt_to_s(trans_balance(bal))) }
  end

  def open_transactions
    all_transactions.select do |item|
      (['Current', 'Past due', 'Future', 'Installment'].include? trans_status(item)) && !trans_disputed(item) ||
          (trans_type(item) == 'Payment' && trans_status(item) == 'Unapplied')
    end
  end

  def open_charges
    transactions_by_type(all_transactions, 'Charge') & open_transactions
  end

  def last_update_date
    Time.strptime(summary['lastUpdateDate'], '%Y-%m-%d').strftime('%m/%d/%y')
  end

  def amt_to_s(amount)
    (sprintf '%.2f', amount).to_s
  end

  def formatted_date(date_string)
    Time.parse(date_string).strftime('%m/%d/%y')
  end

end
