module HubEdos
  class AcademicStatus < Student

    include CampusSolutions::AcademicProfileFeatureFlagged
    include Cache::UserCacheExpiry

    def initialize(options = {})
      super(options)
    end

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/academic-status"
    end

    def json_filename
      'hub_academic_status.json'
    end

    def include_fields
      %w(academicStatuses awardHonors degrees holds)
    end

    def get
      return {} unless is_feature_enabled
      response = self.class.smart_fetch_from_cache(id: instance_key) do
        get_internal
      end
      decorate_internal_response response
    end

  end
end
