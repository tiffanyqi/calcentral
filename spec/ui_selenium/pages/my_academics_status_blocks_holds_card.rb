module CalCentralPages

  class MyAcademicsStatusBlocksHoldsCard < MyAcademicsPage

    include PageObject
    include CalCentralPages
    include ClassLogger

    # Registration
    table(:status_table, :class => 'cc-academics-status-holds-blocks-status-table')
    span(:reg_status_summary, :xpath => '//tr[@data-ng-if="api.user.profile.features.regstatus"]//span[@data-ng-bind="regStatus.summary"]')
    div(:reg_status_explanation, :xpath => '//td[@data-ng-bind-html="regStatus.explanation"]')
    image(:reg_status_icon_green, :xpath => '//tr[@data-ng-if="api.user.profile.features.regstatus"]//i[@class="cc-icon fa fa-check-circle cc-icon-green"]')
    image(:reg_status_icon_red, :xpath => '//tr[@data-ng-if="api.user.profile.features.regstatus"]//i[@class="cc-icon fa fa-exclamation-circle cc-icon-red"]')

    # Residency
    span(:res_status_summary, :xpath => '//span[@data-ng-bind="residency.official.description"]')
    image(:res_status_icon_green, :xpath => '//div[contains(.,"California Residency")]/following-sibling::div/i[@class="cc-icon fa fa-check-circle cc-icon-green ng-scope"]')
    image(:res_status_icon_gold, :xpath => '//div[contains(.,"California Residency")]/following-sibling::div/i[@class="cc-icon fa fa-warning cc-icon-gold ng-scope"]')
    image(:res_status_icon_red, :xpath => '//div[contains(.,"California Residency")]/following-sibling::div/i[@class="cc-icon fa fa-exclamation-circle cc-icon-red ng-scope"]')
    span(:res_from_term, :xpath => '//span[@data-ng-bind="residency.fromTerm.label"]')
    div(:res_msg, :xpath => '//div[@data-ng-bind-html="residency.message.description"]')
    link(:res_slr_link, :xpath => '//a[contains(text(),"Statement of Legal Residence")]')

    # Holds (service indicators)
    h3(:active_holds_heading, :xpath => '//h3[text()="Active Holds"]')
    table(:active_holds_table, :xpath => '//div[@data-ng-if="holds.serviceIndicators.length"]/table')
    elements(:active_holds_row, :row, :xpath => '//div[@data-ng-if="holds.serviceIndicators.length"]/table//tr')
    div(:active_hold_message, :xpath => '//div[@data-ng-if="indicator.instructions"]')
    span(:active_hold_term, :xpath => '//span[@data-ng-bind="indicator.startTermDescr"]')
    div(:no_active_holds_message, :xpath => '//div[contains(text(),"You have no active holds at this time.")]')

    # Blocks
    h3(:active_blocks_heading, :xpath => '//h3[text()="Active Blocks"]')
    table(:active_blocks_table, :xpath => '//div[@data-ng-if="regblocks.activeBlocks.length"]/table')
    cell(:active_block_message, :xpath => '//td[@data-cc-compile-directive="block.message"]')
    div(:no_active_blocks_message, :xpath => '//div[contains(text(),"You have no active blocks at this time.")]')

    # Block history
    button(:show_block_history_button, :xpath => '//button[contains(.,"Show Block History")]')
    button(:hide_block_history_button, :xpath => '//button[contains(.,"Hide Block History")]')
    table(:inactive_blocks_table, :xpath => '//h3[text()="Block History"]/following-sibling::div/table')
    paragraph(:no_inactive_blocks_message, :xpath => '//p/strong[contains(text(),"No block history")]')

    def show_block_history
      WebDriverUtils.wait_for_page_and_click show_block_history_button_element
    end

    def hide_block_history
      WebDriverUtils.wait_for_page_and_click hide_block_history_button_element
    end

    def active_block_count
      active_blocks_table_element.when_visible WebDriverUtils.academics_timeout
      active_blocks_table_element.rows - 1
    end

    def active_block_types
      types = active_blocks_table_element.map { |row| row[0].text }
      types.drop 1
    end

    def active_block_reasons
      reasons = active_blocks_table_element.map { |row| row[1].text }
      reasons.drop 1
    end

    def active_block_offices
      offices = active_blocks_table_element.map { |row| row[2].text }
      offices.drop 1
    end

    def active_block_dates
      dates = active_blocks_table_element.map { |row| row[3].text }
      dates.drop 1
    end

    def inactive_block_count
      inactive_blocks_table_element.rows - 1
    end

    def inactive_block_types
      types = inactive_blocks_table_element.map { |row| row[0].text }
      types.drop 1
    end

    def inactive_block_dates
      dates = inactive_blocks_table_element.map { |row| row[1].text }
      dates.drop 1
    end

    def inactive_block_cleared_dates
      dates = inactive_blocks_table_element.map { |row| row[2].text }
      dates.drop(1).sort!
    end

    def active_hold_count
      active_holds_table_element.when_visible WebDriverUtils.academics_timeout
      active_holds_table_element.rows - 1
    end

    def active_hold_reasons
      types = active_holds_table_element.map { |row| row[0].text }
      types.drop 1
    end

    def active_hold_dates
      types = active_holds_table_element.map { |row| row[1].text }
      types.drop 1
    end

    def expand_hold_detail(row_index)
      active_holds_table_element[row_index].click
    end
  end
end
