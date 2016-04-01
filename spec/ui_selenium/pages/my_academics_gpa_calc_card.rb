module CalCentralPages

  class MyAcademicsGPACalcCard

    include PageObject
    include ClassLogger

    h2(:gpa_calc_heading, :xpath => '//h2[text()="GPA Calculator"]')
    elements(:course, :td, :xpath => '//td[@data-ng-bind="course.course_code"]')
    elements(:units, :td, :xpath => '//td[contains(@data-ng-bind,"units | number:1")]')
    td(:current_gpa, :xpath => '//strong[@data-ng-bind="gpaUnits.cumulativeGpa || \'N/A\'"]')
    td(:est_gpa, :xpath => '//strong[contains(@data-ng-bind,"estimatedGpa")]')
    td(:cum_gpa, :xpath => '//strong[contains(@data-ng-bind,"estimatedCumulativeGpa")]')

    def all_classes
      course_elements.map &:text
    end

    def all_units
      units_elements.map &:text
    end

    def all_selected_grade_options(driver)
      grade_options = driver.find_elements(:xpath => '//select[@data-ng-model="estimated.estimatedGrade"]')
      grade_options.collect! { |select| select.find_elements(:tag_name, 'option') }
      grade_options.flatten!
      grade_options.delete_if { |option| !option.attribute('selected') }
      grade_options.collect { |option| option.text }
    end
  end
end
