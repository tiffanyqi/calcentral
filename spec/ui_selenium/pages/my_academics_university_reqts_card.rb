module CalCentralPages

  class MyAcademicsUniversityReqtsCard < MyAcademicsPage

    # UNIVERSITY UNDERGRAD REQTS
    table(:reqts_table, :xpath => '//h2[text()="University Requirements"]/../following-sibling::div//table')
    div(:no_reqts_msg, :xpath => '//div[@data-ng-if="!academics.universityRequirements || (academics.universityRequirements.length == 0)"]')
    span(:writing_reqt_met, :xpath => '//span[text()="UC Entry Level Writing"]/following-sibling::span')
    link(:writing_reqt_unmet, :xpath => '//span[text()="UC Entry Level Writing"]/following-sibling::span/a[contains(.,"Incomplete")]')
    span(:history_reqt_met, :xpath => '//span[text()="American History"]/following-sibling::span')
    link(:history_reqt_unmet, :xpath => '//span[text()="American History"]/following-sibling::span/a[contains(.,"Incomplete")]')
    span(:institutions_reqt_met, :xpath => '//span[text()="American Institutions"]/following-sibling::span')
    link(:institutions_reqt_unmet, :xpath => '//span[text()="American Institutions"]/following-sibling::span/a[contains(.,"Incomplete")]')
    span(:cultures_reqt_met, :xpath => '//span[text()="American Cultures"]/following-sibling::span')
    link(:cultures_reqt_unmet, :xpath => '//span[text()="American Cultures"]/following-sibling::span/a[contains(.,"Incomplete")]')

  end

end
