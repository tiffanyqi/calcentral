module HubEdos
  class Demographics < Student

    def initialize(options = {})
      super(options)
    end

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/demographic"
    end

    def json_filename
      'hub_demographics.json'
    end

    def include_fields
      %w(ethnicities languages usaCountry foreignCountries birth gender)
    end

  end
end
