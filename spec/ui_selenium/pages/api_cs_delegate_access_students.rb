class ApiCSDelegateAccessStudents

  include PageObject
  include ClassLogger

  def get_json(driver)
    logger.info 'Parsing delegated access students from CS'
    navigate_to "#{WebDriverUtils.base_url}/api/campus_solutions/delegate_access/students"
    wait = Selenium::WebDriver::Wait.new :timeout => WebDriverUtils.page_load_timeout
    wait.until { driver.find_element :xpath => '//pre[contains(.,"200")]' }
    body = driver.find_element(:xpath, '//pre').text
    @parsed = JSON.parse body
  end

  def students
    @parsed['feed']['students']
  end

  def student_names
    names = []
    students.each { |student| names << student['fullName'] }
    names.sort!
  end

end
