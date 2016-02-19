module CalCentralPages

  class MyAcademicsGPACalcCard

    include PageObject
    include ClassLogger

    td(:est_gpa, :xpath => '//strong[contains(@data-ng-bind,"estimatedGpa")]')
    td(:cum_gpa, :xpath => '//strong[contains(@data-ng-bind,"estimatedCumulativeGpa")]')

  end

end
