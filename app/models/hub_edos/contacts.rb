module HubEdos
  class Contacts < Student

    def initialize(options = {})
      super(options)
      @include_fields = options[:include_fields] || %w(identifiers names addresses phones emails urls emergencyContacts confidential)
      @instance_key = Cache::KeyGenerator.per_view_as_type @uid, options
    end

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/contacts"
    end

    def json_filename
      'hub_contacts.json'
    end

    def include_fields
      @include_fields
    end

    def instance_key
      @instance_key
    end

  end
end
