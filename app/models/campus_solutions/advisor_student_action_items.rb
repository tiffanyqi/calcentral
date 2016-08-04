module CampusSolutions
  class AdvisorStudentActionItems < Proxy
    include CampusSolutionsIdRequired

    def xml_filename
      'advisor_student_action_items.xml'
    end

    def url
      "#{@settings.base_url}/UC_AA_ADV_ACTION_ITEM.v1/?EMPLID=#{@campus_solutions_id}&CALLER_TYPE=ADVISOR"
    end

  end
end
