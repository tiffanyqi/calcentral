module CampusSolutions
  class AdvisorStudentRelationship < Proxy

    include CampusSolutionsIdRequired

    def xml_filename
      'advisor_student_relationship.xml'
    end

    def url
      "#{@settings.base_url}/UC_AA_ADV_STDNT_REL.v1/?EMPLID=#{@campus_solutions_id}"
    end

  end
end
