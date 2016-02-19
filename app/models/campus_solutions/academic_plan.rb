module CampusSolutions
  class AcademicPlan < Proxy

    include CampusSolutionsIdRequired
    include EnrollmentCardFeatureFlagged

    def initialize(options = {})
      super options
      @term_id = options[:term_id]
      initialize_mocks if @fake
    end

    def build_feed(response)
      (response && response['UC_SR_ACADEMIC_PLANNER']) || {}
    end

    def xml_filename
      'academic_plan.xml'
    end

    def url
      "#{@settings.base_url}/UC_SR_ACADEMIC_PLANNER.v1/get?EMPLID=#{@campus_solutions_id}".tap do |url|
        url << "&STRM=#{@term_id}" if @term_id
      end
    end

  end
end
