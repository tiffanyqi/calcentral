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
      # Make sure response is well-structured.
      container = response.parsed_response['STUDENTS']['STUDENT']['EMERGENCY_CONTACTS']
      return response if container.blank?

      # Make emergency_contact into an array.
      contacts = container['EMERGENCY_CONTACT'] = Array.wrap container['EMERGENCY_CONTACT']

      # Make emergency_phones into an array.
      contacts.each do |contact|
        phones = contact['EMERGENCY_PHONES']
        if phones
          contact['EMERGENCY_PHONES'] = Array.wrap phones['EMERGENCY_PHONE']
        else
          contact['EMERGENCY_PHONES'] = []
        end
      end

      # Put the primary_contact with 'Y' at the head position, values being either 'Y' or 'N'
      contacts.sort! do |left, right|
        right['PRIMARY_CONTACT'] <=> left['PRIMARY_CONTACT']
      end

      response
    end

    def url
      "#{@settings.base_url}/UcApiEmergencyContactGet.v1/?EMPLID=#{@campus_solutions_id}"
    end

  end
end
