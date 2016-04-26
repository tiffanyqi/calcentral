module HubEdos
  class Registrations < Proxy

    include CampusSolutions::AcademicProfileFeatureFlagged
    include Cache::UserCacheExpiry

    def initialize(options = {})
      super(options)
      @term_id = options[:term_id]
    end

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/registrations?term-id=#{@term_id}"
    end

    def json_filename
      'hub_registrations.json'
    end

    def include_fields
      %w(affiliations registrations)
    end

    def get
      return {} unless is_feature_enabled
      response = self.class.smart_fetch_from_cache(id: instance_key) do
        get_internal
      end
      decorate_internal_response response
    end

    def build_feed(response)
      resp = parse_response response
      get_students(resp)
    end

    def instance_key
      "#{@uid}-#{@term_id}"
    end

    def wrapper_keys
      %w(apiResponse response any)
    end

  end
end
