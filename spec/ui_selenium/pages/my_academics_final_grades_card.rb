module CalCentralPages

  class MyAcademicsFinalGradesCard < MyAcademicsPage

    include PageObject
    include ClassLogger

    h2(:final_grades_heading, :xpath => '//h2[text()="Final Grades"]')
    h4(:no_grades_heading, :xpath => '//h4[contains(text(),"No grade data available for")]')
    elements(:course, :td, :xpath => '//td[@data-ng-bind="course.course_code"]')
    elements(:units, :td, :xpath => '//td[@data-ng-bind="transcript.units | number:1"]')
    elements(:grade, :span, :xpath => '//h2[text()="Final Grades"]/../following-sibling::div//tbody[@data-ng-repeat="course in selectedCourses"]/tr/td[3]')
    button(:show_more, :xpath => '//button[text()="Show more"]')
    button(:show_less, :xpath => '//button[text()="Show less"]')
    link(:bear_facts_link, :xpath => '//a[contains(text(),"Bear Facts")]')

    def show_more
      WebDriverUtils.wait_for_element_and_click show_more_element
    end

    def show_less
      WebDriverUtils.wait_for_element_and_click show_less_element
    end

    def all_classes
      classes = []
      course_elements.each { |course| classes << course.text }
      classes
    end

    def all_units
      units = []
      units_elements.each { |unit| units << unit.text }
      units
    end

    def all_grades
      grades = []
      grade_elements.each { |grade| grades << grade.text }
      grades
    end

  end
end
