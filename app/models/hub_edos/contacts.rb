module HubEdos
  class Contacts < Student

    def initialize(options = {})
      super(options)
    end

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/contacts"
    end

    def json_filename
      'hub_contacts.json'
    end

    def include_fields
      %w(identifiers names addresses phones emails urls emergencyContacts confidential)
    end

  end
end
