class ApiCSResidencyMessagePage

  include PageObject
  include ClassLogger

  def get_json(driver, code)
    logger.info 'Fetching data from /api/campus_solutions/residency_message'
    navigate_to "#{WebDriverUtils.base_url}/api/campus_solutions/residency_message?messageNbr=#{code}"
    @parsed = JSON.parse driver.find_element(:xpath => '//pre').text
  end

  def message
    @parsed['feed'] && @parsed['feed']['root'] && @parsed['feed']['root']['getMessageCatDefn'] && @parsed['feed']['root']['getMessageCatDefn']['descrlong']
  end

  # Remove link markup from the message strings
  def message_text
    message && message.gsub(%r{</?[^>]+?>}, '')
  end

end
