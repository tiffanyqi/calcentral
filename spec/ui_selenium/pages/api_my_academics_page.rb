class ApiMyAcademicsPage

  include PageObject
  include ClassLogger

  element(:json_body, :xpath => '//pre')

  def get_json(driver)
    logger.info('Parsing JSON from /api/my/academics')
    navigate_to "#{WebDriverUtils.base_url}/api/my/academics"
    wait = Selenium::WebDriver::Wait.new(:timeout => WebDriverUtils.academics_timeout)
    wait.until { driver.find_element(:xpath => '//pre[contains(.,"MyAcademics::Merged")]') }
    body = driver.find_element(:xpath, '//pre').text
    @parsed = JSON.parse(body)
  end

  def academics_date(epoch)
    (Time.strptime(epoch, '%s')).strftime("%a %b %-d")
  end

  def academics_time(epoch)
    time_format = (Time.strptime(epoch, '%s')).strftime("%-l:%M %p")
    (time_format == '12:00 PM') ? 'Noon' : time_format
  end

  # PROFILE

  def college_and_level
    @parsed['collegeAndLevel']
  end

  # Use case for multiple careers is Law + MBA
  def careers
    college_and_level['careers']
  end

  def has_no_standing?
    college_and_level['empty']
  end

  def level
    college_and_level['level']
  end

  def non_ap_level
    college_and_level['nonApLevel']
  end

  def gpa_units
    @parsed['gpaUnits']
  end

  def gpa
    gpa_units['cumulativeGpa']
  end

  def ttl_units
    units = gpa_units['totalUnits']
    if units.nil?
      nil
    else
      (units == units.floor) ? units.floor : units
    end
  end

  def units_attempted
    gpa_units['totalUnitsAttempted']
  end

  def colleges_and_majors
    college_and_level['majors']
  end

  def colleges
    colleges = []
    colleges_and_majors.each do |college_and_major|
      # For double majors within the same college, only show the college once
      colleges << college_and_major['college'] unless college_and_major['college'] == ''
    end
    colleges
  end

  def majors
    majors = []
    colleges_and_majors.each { |college_and_major| majors << college_and_major['major'].split.join(' ') }
    majors
  end

  def term_name
    college_and_level['termName']
  end

  def transition_term
    @parsed['transitionTerm']
  end

  def transition_term?
    transition_term.nil? ? false : true
  end

  def trans_term_name
    transition_term['termName']
  end

  def trans_term_registered?
    transition_term['registered']
  end

  def trans_term_profile_current?
    transition_term['isProfileCurrent']
  end

  # UNDERGRAD REQUIREMENTS

  def requirements
    @parsed['requirements'].inject({}) { |map, reqt| map[reqt['name']] = reqt; map }
  end

  def writing_reqt_met?
    reqt = requirements['UC Entry Level Writing']
    if reqt['status'] == 'met'
      true
    else
      false
    end
  end

  def history_reqt_met?
    reqt = requirements['American History']
    if reqt['status'] == 'met'
      true
    else
      false
    end
  end

  def institutions_reqt_met?
    reqt = requirements['American Institutions']
    if reqt['status'] == 'met'
      true
    else
      false
    end
  end

  def cultures_reqt_met?
    reqt = requirements['American Cultures']
    if reqt['status'] == 'met'
      true
    else
      false
    end
  end

  # BLOCKS

  def active_blocks
    @parsed['regblocks']['activeBlocks']
  end

  def inactive_blocks
    @parsed['regblocks']['inactiveBlocks']
  end

  def block_type(item)
    item['type']
  end

  def block_reason(item)
    item['reason']
  end

  def block_office(item)
    item['office']
  end

  def block_date(item)
    item['blockedDate']['dateString']
  end

  def block_message(item)
    item['message']
  end

  def block_cleared_date(item)
    item['clearedDate']['dateString']
  end

  def active_block_types
    types = []
    active_blocks.select do |item|
      type = block_type(item)
      types.push(type)
    end
    types
  end

  def active_block_reasons
    reasons = []
    active_blocks.select do |item|
      reason = block_reason(item)
      reasons.push(reason)
    end
    reasons
  end

  def active_block_offices
    offices = []
    active_blocks.select do |item|
      office = block_office(item)
      offices.push(office)
    end
    offices
  end

  def active_block_dates
    dates = []
    active_blocks.select do |item|
      date = (Time.strptime(block_date(item), '%m/%d/%Y')).strftime('%m/%d/%y')
      dates.push(date)
    end
    dates
  end

  def inactive_block_types
    types = []
    inactive_blocks.select do |item|
      type = block_type(item)
      types.push(type)
    end
    types
  end

  def inactive_block_dates
    dates = []
    inactive_blocks.select do |item|
      date = (Time.strptime(block_date(item), '%m/%d/%Y')).strftime('%m/%d/%y')
      dates.push(date)
    end
    dates
  end

  def inactive_block_cleared_dates
    dates = []
    inactive_blocks.select do |item|
      date = (Time.strptime(block_cleared_date(item), '%m/%d/%Y')).strftime('%m/%d/%y')
      dates.push(date)
    end
    dates.sort!
  end

  # FINAL EXAMS

  def exam_schedules
    @parsed['examSchedule']
  end

  def has_exam_schedules
    (exam_schedules.nil? || !exam_schedules.any?) ? false : true
  end

  def exam_epochs
    epochs = []
    exam_schedules.each { |schedule| epochs.push(schedule['date']['epoch'].to_s) }
    epochs
  end

  def all_exam_dates
    dates = []
    exam_epochs.each { |epoch| dates.push(academics_date(epoch)) }
    dates
  end

  def all_exam_times
    times = []
    exam_schedules.each { |exam| times.push(exam['time']) }
    times
  end

  def all_exam_courses
    courses = []
    exam_schedules.each { |schedule| courses.push(schedule['course_code']) }
    courses
  end

  def exam_locations(exam)
    locations = exam['locations']
    raw_locations = []
    locations.each { |location| raw_locations.push(location['raw'].gsub("  ", " ").strip) }
    raw_locations
  end

  def all_exam_locations
    all_locations = []
    exam_schedules.each { |exam| all_locations.concat(exam_locations(exam)) }
    all_locations.sort
  end

  # OTHER SITE MEMBERSHIPS

  def other_site_memberships
    @parsed['otherSiteMemberships']
  end

  def other_sites(semester_name)
    sites = []
    other_site_memberships.nil? ? nil : other_site_memberships.each { |membership| sites.concat(membership['sites']) if membership['name'] == semester_name }
    sites
  end

  def other_site_names(sites)
    names = []
    sites.each { |site| names.push(site['name']) }
    names
  end

  def other_site_descriptions(sites)
    descriptions = []
    sites.each { |site| descriptions.push(site['shortDescription'].gsub('  ', ' ')) }
    descriptions
  end

end
