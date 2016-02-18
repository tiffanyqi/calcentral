class ApiMyBadgesPage

  include PageObject
  include ClassLogger

  def get_json(driver)
    logger.info('Parsing JSON from /api/my/badges')
    navigate_to "#{WebDriverUtils.base_url}/api/my/badges"
    body = driver.find_element(:xpath, '//pre').text
    @parsed = JSON.parse(body)
  end

  def student_info
    @parsed['studentInfo']
  end

  def residency
    student_info['californiaResidency']
  end

  def residency_summary
    residency['summary']
  end

  def residency_explanation
    residency['explanation']
  end

  def residency_needs_action
    residency['needsAction']
  end

  def reg_status
    student_info['regStatus']
  end

  def reg_status_summary
    reg_status['summary']
  end

  def reg_status_explanation
    reg_status['explanation']
  end

  def reg_status_needs_action
    reg_status['needsAction']
  end

  def reg_block
    student_info['regBlock']
  end

  def active_block_needs_action
    reg_block['needsAction']
  end

  def active_block_number_str
    reg_block['activeBlocks'].to_s
  end

end
