class ApiMyFinAidPage

  include PageObject
  include ClassLogger

  def get_json(driver)
    logger.info 'Parsing JSON from /api/my/finaid'
    navigate_to "#{WebDriverUtils.base_url}/api/my/finaid"
    @parsed = JSON.parse driver.find_element(:xpath, '//pre').text
  end

  def title(item)
    item['title']
  end

  def summary(item)
    item['summary']
  end

  def source(item)
    item['source']
  end

  def type(item)
    item['type']
  end

  def date(item)
    item['date']
  end

  def date_epoch(item)
    Time.at(date(item)['epoch'])
  end

  def term_year(item)
    item['termYear']
  end

  def status(item)
    item['status']
  end

  def source_url(item)
    item['sourceUrl']
  end

  def all_activity
    @parsed['activities']
  end

  def undated_messages
    dateless_messages = all_activity.select { |item| date(item).blank? }
    dateless_messages.sort_by { |item| title(item) }
  end

  def dated_messages
    dated_messages = all_activity.select { |item| !date(item).blank? }
    sorted_messages = dated_messages.sort_by { |item| date_epoch(item) }
    sorted_messages.reverse!
  end

  def all_messages_sorted
    undated_messages.push(*dated_messages)
  end

  def all_message_titles_sorted
    all_messages_sorted.map { |message| title(message).gsub(/\s+/, ' ') }
  end

  def all_message_summaries_sorted
    all_messages_sorted.map { |message| summary(message).gsub(/\s+/, '') }
  end

  def all_message_sources_sorted
    all_messages_sorted.map { |message| source message }
  end

  def all_message_dates_sorted
    all_messages_sorted.map do |message|
      unless date(message).blank?
        date = date_epoch(message)
        ui_date = date.strftime('%b %-d')
        # Include the year in the visible date if it does not match the current year
        ui_date << date.strftime(' %Y') if date.strftime('%Y') != Date.today.strftime('%Y')
        ui_date
      end
    end
  end

  def all_message_source_urls_sorted
    all_messages_sorted.map { |message| source_url(message).gsub(/\/\s*\z/, '') }
  end

  def all_message_types_sorted
    all_messages_sorted.map { |message| type message }
  end

  def all_undated_alert_messages
    undated_messages.map { |message| message if type(message) == 'alert' }
  end

  def all_message_years_sorted
    all_messages_sorted.map { |message| term_year message }
  end

  def all_message_statuses_sorted
    all_messages_sorted.map { |message| status message }
  end

end
