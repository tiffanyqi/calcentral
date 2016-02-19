module CalCentralPages

  class MyAcademicsFinalGradesCard < MyAcademicsPage

    include PageObject
    include ClassLogger

    elements(:grade, :span, :xpath => '//span[@data-ng-bind="transcript.grade"]')

  end

end
