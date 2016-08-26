module HubEdos
  class Affiliations < Student
    include HubEdos::CachedProxy
    include Cache::UserCacheExpiry

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/affiliation"
    end

    def json_filename
      'hub_affiliations.json'
    end

    def include_fields
      %w(affiliations identifiers)
    end

  end
end
