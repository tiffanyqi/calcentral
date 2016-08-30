module HubEdos
  class Contacts < Student
    include HubEdos::CachedProxy
    include Cache::UserCacheExpiry

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/contacts"
    end

    def json_filename
      'hub_contacts.json'
    end

    def whitelist_fields
      %w(identifiers affiliations names addresses phones emails urls emergencyContacts confidential)
    end

  end
end
