class ApiMyBadgesPage

  include PageObject
  include ClassLogger

  def get_json(driver)
    logger.info 'Parsing JSON from /api/my/badges'
    navigate_to "#{WebDriverUtils.base_url}/api/my/badges"
    @parsed = JSON.parse driver.find_element(:xpath, '//pre').text
  end
end
