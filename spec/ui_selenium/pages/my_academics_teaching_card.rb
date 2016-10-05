module CalCentralPages

  class MyAcademicsTeachingCard < MyAcademicsPage

    include PageObject
    include CalCentralPages

    h2(:teaching_heading, :xpath => '//h2[text()="Teaching"]')
    elements(:semester_link, :link, :xpath => '//div[contains(@data-ng-if,"hasTeachingClasses")]//a[@data-ng-bind="semester.name"]')
    elements(:course_code, :link, :xpath => '//a[@data-ng-bind="listing.course_code"]')
    button(:show_more, :xpath => '//button[@data-ng-if="pastSemestersTeachingCount > 1"]/span[text()="Show More"]')
    button(:show_less, :xpath => '//button[@data-ng-if="pastSemestersTeachingCount > 1"]/span[text()="Show Less"]')

    def teaching_terms_visible?(term_names)
      terms_in_ui = []
      semester_link_elements.each { |link| terms_in_ui.push(link.text) }
      if terms_in_ui.sort == term_names.sort
        true
      else
        false
      end
    end

    def all_semester_course_codes(driver, semester_name)
      codes = []
      code_elements = driver.find_elements(:xpath, "//div[contains(@data-ng-if,'hasTeachingClasses')]//a[text()='#{semester_name}']/../following-sibling::div//a[@data-ng-bind='listing.course_code']")
      code_elements.each { |element| codes.push(element.text) }
      codes
    end

    def all_semester_course_titles(driver, semester_name)
      titles = []
      title_elements = driver.find_elements(:xpath => "//div[contains(@data-ng-if,'hasTeachingClasses')]//a[text()='#{semester_name}']/../following-sibling::div//div[@data-ng-bind='class.title']")
      title_elements.each { |element| titles.push(element.text) }
      titles
    end
  end
end
