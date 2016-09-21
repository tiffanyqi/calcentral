module CampusSolutions
  class StudentOutstandingBalance < CachedProxy

    include StudentSuccessFeatureFlagged
    include CampusSolutionsIdRequired

    def url
      "#{@settings.base_url}/UC_SF_STDNT_OS_BAL.v1/Get?EMPLID=#{@campus_solutions_id}"
    end

    def xml_filename
      'student_outstanding_balance.xml'
    end
  end
end
