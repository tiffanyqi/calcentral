module HubEdos
  class Affiliations < Student

    def initialize(options = {})
      super(options)
    end

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/affiliation"
    end

    def json_filename
      'hub_affiliations.json'
    end

    def include_fields
      %w(affiliations)
    end

  end
end
