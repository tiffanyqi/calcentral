class ApiCSFinAidDataPage

  include PageObject
  include ClassLogger

  def get_json(driver, year)
    logger.info "Parsing FinAid data from CS for aid year #{year}"
    navigate_to "#{WebDriverUtils.base_url}/api/campus_solutions/financial_aid_data?aid_year=#{year}"
    @parsed = JSON.parse driver.find_element(:xpath, '//pre').text
  end

  def feed
    @parsed['feed']
  end

  # FIN AID SUMMARY

  def fin_aid_summary
    feed['financialAidSummary']
  end

  def net_cost
    fin_aid_summary['netCost'] unless fin_aid_summary.nil?
  end

  def net_cost_ttl
    net_cost['total']
  end

  def net_cost_amt
    net_cost_ttl['amount'] unless net_cost_ttl.nil?
  end

  def funding_offered
    fin_aid_summary['fundingOffered'] unless fin_aid_summary.nil?
  end

  def funding_offered_ttl
    funding_offered['total'] unless funding_offered.nil?
  end

  def funding_offered_amt
    funding_offered_ttl['amount'] unless funding_offered_ttl.nil?
  end

  def funding_category(title)
    funding_offered['categories'].find { |category| category['total']['title'] == title }
  end

  def funding_category_ttl(title)
    category = funding_category title
    category.nil? ? nil : category['total']
  end

  def funding_category_amt(title)
    funding_category_ttl(title)['amount'] unless funding_category_ttl(title).nil?
  end

  def funding_category_items(title)
    category = funding_category title
    category['items'] unless category.nil?
  end

  def funding_category_item(items, item_title)
    items.find { |item| item['title'] == item_title } unless items.nil?
  end

  def funding_category_item_amt(item)
    item['amount'] unless item.nil?
  end

  def shopping_sheet_url
    feed['shoppingSheet']['url'] unless feed['shoppingSheet'].nil?
  end

  # BUDGET (COST OF ATTENDANCE)

  def budget
    feed['coa']
  end

  def item_title(item)
    item['title']
  end

  def item_total(item)
    item['total']
  end

  def item_amounts(item)
    item['amounts']
  end

  def sub_items(item)
    item['subItems']
  end

  def budget_annual_data
    budget['fullyear'].nil? ? nil : budget['fullyear']['data']
  end

  def budget_term_data
    budget['semester'].nil? ? nil : budget['semester']['data']
  end

  def budget_total
    if budget_annual_data.nil?
      nil
    else
      item = budget_annual_data.first['items'].find { |item| item['totals'] }
      item['totals'].first
    end
  end

  def budget_items(budget_data, items_title)
    items = []
    data_set = budget_data.find { |data| item_title(data) == items_title }
    data_set['items'].each { |item| items << item if item_total(item) } unless data_set.nil?
    items
  end

  def budget_item_titles(budget_data, items_title)
    titles = []
    budget_items(budget_data, items_title).each { |item| titles << item_title(item) }
    titles
  end

  def budget_item_amounts(budget_data, items_title)
    amounts = []
    budget_items(budget_data, items_title).each { |item| amounts << item_amounts(item) }
    amounts
  end

  def budget_item_totals(budget_data, items_title)
    totals = []
    budget_items(budget_data, items_title).each { |item| totals << item_total(item) }
    totals
  end

  def budget_sub_item_titles(item)
    titles = []
    sub_items(item).each { |sub_item| titles << item_title(sub_item) }
    titles
  end

  def budget_sub_item_totals(item)
    amounts = []
    sub_items(item).each { |sub_item| amounts << item_total(sub_item) }
    amounts
  end

  def budget_sub_item_amounts(item)
    amounts = []
    sub_items(item).each do |sub_item|
      amounts.concat item_amounts(sub_item)
    end
    amounts
  end

  # PROFILE

  def status_categories
    feed['status']['categories']
  end

  def profile
    status_categories.find { |category| category['title'] == 'Financial Aid Profile' }
  end

  def profile_items
    items = []
    profile['itemGroups'].each { |group| items += group }
    items
  end

  def profile_item(type)
    profile_items.find { |item| item['title'] == type }
  end

  def profile_value(type)
    profile_item(type)['value'] unless profile_item(type).nil?
  end

  def profile_values(type)
    items = profile_items.select { |item| item['title'] == type }
    values = []
    items.each { |item| values << item['value'] }
    values
  end

  def profile_sub_values(type)
    values = []
    profile_item(type)['values'].each do |value|
      ui_sub_values = []
      value['subvalue'].each { |sub_value| ui_sub_values << sub_value.gsub(/[^a-zA-Z0-9]/, ' ').gsub(/\s+/, ' ') }
      values << ui_sub_values.join(' ')
    end
    values
  end

  def terms_and_conditions
    status_categories.find { |category| category['title'] == 'Terms and Conditions' }
  end

end
