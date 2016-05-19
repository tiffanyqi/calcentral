class ApiCSHoldsPage

  include PageObject
  include ClassLogger

  def get_json(driver)
    logger.info 'Fetching data from /api/campus_solutions/holds'
    navigate_to "#{WebDriverUtils.base_url}/api/campus_solutions/holds"
    @parsed = JSON.parse driver.find_element(:xpath => '//pre')
  end

  def holds
    @parsed['feed']['serviceIndicators']
  end

  def hold_reasons
    holds.map { |hold| hold['reasonDescr'] }
  end

  def hold_dates
    holds.map do |hold|
      # Shows the start term if there is no start date
      hold['startDate'].nil? ?
          hold['startTermDesc'] :
          WebDriverUtils.ui_numeric_date_format(Time.strptime(hold['startDate']['epoch'], '%s'))
    end
  end

  def hold_terms
    holds.map { |hold| hold['startTermDesc'] }
  end

  def hold_contacts
    contacts = holds.map { |hold| hold['contactName'] }
    contacts.compact
  end

  def hold_instructions
    instructions = holds.map { |hold| hold['instructions'] }
    instructions.compact
  end

end
