module HubEdos
  class Demographics < Student

    def initialize(options = {})
      super(options)
      @include_fields = options[:include_fields] || %w(ethnicities languages usaCountry foreignCountries birth gender)
      @instance_key = Cache::KeyGenerator.per_view_as_type @uid, options
    end

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/demographic"
    end

    def json_filename
      'hub_demographics.json'
    end

    def include_fields
      @include_fields
    end

    def instance_key
      @instance_key
    end

  end
end
