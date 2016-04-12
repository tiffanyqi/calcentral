class ApiCSFinAidFundingSourcesPage

  include PageObject
  include ClassLogger

  def get_json(driver, year)
    logger.info "Parsing FinAid funding sources data from CS for aid year #{year}"
    navigate_to "#{WebDriverUtils.base_url}/api/campus_solutions/financial_aid_funding_sources?aid_year=#{year}"
    @parsed = JSON.parse driver.find_element(:xpath, '//pre').text
  end

  def feed
    @parsed['feed']
  end

  def awards
    feed['awards']
  end

  def gift_aid_amt
    awards['giftaid']['total']['amount']
  end

end
