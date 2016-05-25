module CampusSolutions
  class EmergencyContacts < CachedProxy

    include CampusSolutionsIdRequired
    include EmergencyContactsFeatureFlagged

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def xml_filename
      'emergency_contacts.xml'
    end

    def build_feed(response)
      return {} unless is_feature_enabled or response.parsed_response.blank?
      normalize_response(response).parsed_response
    end

    def normalize_response(response)
      # Perform several checks and transforms on the response because the campus_solutions API
      # returns inconsistently structured data.

      container = response.parsed_response['STUDENTS']['STUDENT']['EMERGENCY_CONTACTS']
      return response if container.blank?

      contacts = container['EMERGENCY_CONTACT']

      contacts.sort! do |left, right|
        # Put the primary_contact with 'Y' at the head position, values being either 'Y' or 'N'
        right['PRIMARY_CONTACT'] <=> left['PRIMARY_CONTACT']
      end

      contacts.each do |item|
        # The campus_solutions API returns the following structure:
        # When a contact has one phone, emergency_phone points to that phone;
        # When a contact has more than one phone, then emergency_phone points to an array of phones;
        # We fix that by making emergency_phone into an array, always.
        phones = item['EMERGENCY_PHONES']

        if phones
          phones['EMERGENCY_PHONE'] = Array.wrap phones['EMERGENCY_PHONE']
        else
          item['EMERGENCY_PHONES'] = {"EMERGENCY_PHONE" => []}
        end
      end

      response
    end

    def url
      "#{@settings.base_url}/UcApiEmergencyContactGet.v1/?EMPLID=#{@campus_solutions_id}"
    end

  end
end
