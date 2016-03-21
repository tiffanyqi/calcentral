module CalCentralPages

  class MyAcademicsBookListPage < MyAcademicsPage

    include PageObject
    include CalCentralPages

    def load_page(semester_slug)
      navigate_to "#{WebDriverUtils.base_url}/academics/booklist/#{semester_slug}"
    end

  end
end
