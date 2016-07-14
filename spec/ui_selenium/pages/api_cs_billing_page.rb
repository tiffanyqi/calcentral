class ApiCSBillingPage

  include PageObject
  include ClassLogger

  def get_json(driver)
    logger.info 'Parsing JSON from /api/campus_solutions/billing'
    navigate_to "#{WebDriverUtils.base_url}/api/campus_solutions/billing"
    @parsed = JSON.parse driver.find_element(:xpath, '//pre').text
  end

  def error?
    @parsed['noStudentId']
  end

  def feed
    @parsed['feed']
  end

  def summary
    feed && feed['summary']
  end

  def current_term
    summary['currentTerm']
  end

  def amount_due_now
    summary['amountDueNow']
  end

  def past_due_amount
    summary['pastDueAmount']
  end

  def charges_not_yet_due
    summary['chargesNotYetDue']
  end

  def account_balance
    summary['accountBalance']
  end

  def activity
    feed && feed['activity']
  end

  def line_amount(item)
    item['itemLineAmount']
  end

  def balance(item)
    item['itemBalance']
  end

  def effective_date(item)
    item['itemEffectiveDate']
  end

  def effective_date_as_date(item)
    Date.parse effective_date(item)
  end

  def description(item)
    item['itemDescription']
  end

  def due_date(item)
    item['itemDueDate']
  end

  def ref_description(item)
    item['itemReferenceDescription']
  end

  def status(item)
    item['itemStatus']
  end

  def type(item)
    item['itemType']
  end

  def term_desc(item)
    item['itemTermDescription']
  end

  def due_flag(item)
    item['itemDueFlag']
  end

  def transactions_by_desc(transactions, desc)
    transactions.select { |item| self.description(item) == desc }
  end

  def transactions_by_type(transactions, type)
    transactions.select { |item| self.type(item) == type }
  end

  def transactions_by_term(transactions, term)
    transactions.select { |item| term_desc(item) == term }
  end

  def transactions_by_date_range(start_date, end_date)
    activity.select do |item|
      Date.strptime(start_date, '%m/%d/%Y') <= effective_date_as_date(item) && Date.strptime(end_date, '%m/%d/%Y') >= effective_date_as_date(item)
    end
  end

  def transactions_sum(transactions)
    transactions.inject(BigDecimal.new('0')) { |acc, bal| acc + BigDecimal.new(amt_to_s(balance(bal))) }
  end

  def transactions_unpaid
    activity.select { |item| status(item) == 'Unpaid' }
  end

  def transactions_with_balance
    activity.select { |item| !balance(item).zero? }
  end

  def balance_transactions
    transactions_unpaid & transactions_with_balance
  end

  def open_charges
    transactions_by_type(activity, 'Charge') & transactions_unpaid
  end

  def formatted_date(date_string)
    Time.parse(date_string).strftime('%m/%d/%y')
  end

  def amt_to_s(amount)
    (sprintf '%.2f', amount).to_s
  end

end
