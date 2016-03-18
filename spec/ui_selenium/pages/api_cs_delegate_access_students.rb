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

  def student_uids
    uids = []
    students.each { |student| uids << student['uid'].to_i }
    uids.sort!
  end

  def student_by_uid(uid)
    students.find { |student| student['uid'].to_i == uid }
  end

  def student_names
    names = []
    students.each { |student| names << student['fullName'] }
    names.sort!
  end

  def student_name(uid)
    logger.debug "Searching for a student with UID #{uid}"
    student = students.find { |student| student['uid'] == uid.to_s }
    student['fullName']
  end

  def student_privileges(student)
    student['privileges']
  end

end
