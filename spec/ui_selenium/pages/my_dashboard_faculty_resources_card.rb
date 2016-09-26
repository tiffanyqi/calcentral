module CalCentralPages

  class MyDashboardFacultyResourcesCard < MyDashboardPage

    link(:schedule_of_classes, :xpath => '//a[contains(text(),"Schedule of Classes")]')
    link(:course_catalog, :xpath => '//a[contains(.,"Course Catalog")]')
    link(:assistive_tech, :xpath => '//a[contains(text(),"Assistive Technology")]')
    link(:bcourses, :xpath => '//a[contains(text(),"bCourses")]')
    link(:clickers, :xpath => '//a[contains(text(),"Clickers")]')
    link(:course_capture, :xpath => '//a[contains(text(),"Course Capture")]')
    link(:course_evals, :xpath => '//a[contains(text(),"Course Evaluations")]')
    link(:diy_media, :xpath => '//a[contains(.,"DIY")]')
    link(:acad_innov_studio, :xpath => '//a[contains(text(),"Academic Innovation Studio")]')

  end
end
