class ApiCSHoldsPage

  include PageObject
  include ClassLogger

  def get_json(driver)
    logger.info 'Fetching data from /api/campus_solutions/holds'
    navigate_to "#{WebDriverUtils.base_url}/api/campus_solutions/holds"
    @parsed = JSON.parse driver.find_element(:xpath => '//pre').text
  end

  def holds
    @parsed['feed'] && @parsed['feed']['serviceIndicators']
  end

  def hold_reasons
    holds.map { |hold| hold['reasonDescr'] }
  end

  def hold_dates
    holds.map do |hold|
      # Shows the start term if there is no start date
      hold['startDate'].blank? ?
          hold_term(hold) :
          Time.strptime(hold['startDate']['epoch'].to_s, '%s').strftime('%m/%d/%y')
    end
  end

  def hold_term(hold)
    hold['startTermDescr']
  end

  def hold_contacts(hold)
    hold['contactName']
  end

  def hold_instructions(hold)
    hold['instructions']
  end

end
