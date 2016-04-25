class ApiMyAdvisingPage

  include PageObject
  include ClassLogger

  def get_json(driver)
    logger.info 'Parsing JSON from /api/my/advising'
    navigate_to "#{WebDriverUtils.base_url}/api/my/advising"
    @parsed = JSON.parse driver.find_element(:xpath, '//pre').text
  end

  def college_advisor
    @parsed['caseloadAdvisor'].empty? ? nil : "#{@parsed['caseloadAdvisor']['firstName']} #{@parsed['caseloadAdvisor']['lastName']}"
  end

  def all_future_appts
    @parsed['futureAppointments']
  end

  def all_future_appt_epochs
    all_future_appts.map { |appt| (appt['dateTime'] / 1000).to_s }
  end

  def all_future_appt_dates
    all_future_appt_epochs.map { |epoch| WebDriverUtils.ui_numeric_date_format Time.strptime(epoch, '%s') }
  end

  def all_future_appt_times
    times = []
    all_future_appt_epochs.map do |epoch|
      time_format = (Time.strptime(epoch, '%s')).strftime("%-l:%M %p")
      if time_format == '12:00 PM'
        time = 'Noon'
      else
        time = time_format
      end
      times.push(time)
    end
    times
  end

  def all_future_appt_advisors
    all_future_appts.map { |appt| appt['staff']['name'] }
  end

  def all_future_appt_methods
    all_future_appts.map { |appt| appt['method'].upcase }
  end

  def all_future_appt_locations
    all_future_appts.map { |appt| appt['location'].gsub(/\s+/, ' ').upcase }
  end

  def all_prev_appts
    @parsed['pastAppointments']
  end

  def all_prev_appt_dates
    all_prev_appts.map { |appt| (Time.strptime((appt['dateTime'] / 1000).to_s, '%s')).strftime("%m/%d/%y") }
  end

  def all_prev_appt_advisors
    all_prev_appts.map { |name| name['staff']['name'] }
  end

end
