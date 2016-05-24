module HubEdos
  class Registrations < Proxy

    def initialize(options = {})
      super(options)
    end

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/registrations"
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

    def wrapper_keys
      %w(apiResponse response any)
    end

  end
end
