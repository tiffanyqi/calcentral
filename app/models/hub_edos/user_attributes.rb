module HubEdos
  class UserAttributes

    include User::Student
    include Berkeley::UserRoles
    include ResponseWrapper
    include ClassLogger

    def initialize(options = {})
      @uid = options[:user_id]
    end

    def self.test_data?
      Settings.hub_edos_proxy.fake.present?
    end

    def get_edo
      edo_feed = MyStudent.new(@uid).get_feed
      if (feed = edo_feed[:feed])
        HashConverter.symbolize feed[:student] # TODO will have to dynamically switch student/person EDO somehow
      else
        nil
      end
    end

    def get
      wrapped_result = handling_exceptions(@uid) do
        result = {}
        if (edo = get_edo)
          set_ids(result)
          extract_passthrough_elements(edo, result)
          extract_names(edo, result)
          extract_roles(edo, result)
          extract_emails(edo, result)
          result[:statusCode] = 200
        else
          logger.error "Could not get Student EDO data for UID #{@uid}"
          result[:noStudentId] = true
        end
        result
      end
      wrapped_result[:response]
    end

    def has_role?(*roles)
      if (edo = get_edo)
        result = {}
        extract_roles(edo, result)
        if (user_role_map = result[:roles])
          roles.each do |role|
            return true if user_role_map[role]
          end
        end
      end
      false
    end

    def set_ids(result)
      result[:ldap_uid] = @uid
      result[:campus_solutions_id] = campus_solutions_id
      result[:is_legacy_user] = legacy_user?
      result[:student_id] = lookup_legacy_student_id_from_crosswalk
      result[:delegate_user_id] = lookup_delegate_user_id
    end

    def extract_passthrough_elements(edo, result)
      [:names, :addresses, :phones, :emails, :ethnicities, :languages, :emergencyContacts].each do |field|
        if edo[field].present?
          result[field] = edo[field]
        end
      end
    end

    def extract_names(edo, result)
      # preferred name trumps primary name if present
      find_name('PRI', edo, result) unless find_name('PRF', edo, result)
    end

    def find_name(type, edo, result)
      found_match = false
      if edo[:names].present?
        edo[:names].each do |name|
          if name[:type].present? && name[:type][:code].present?
            if name[:type][:code].upcase == 'PRI'
              result[:given_name] = name[:givenName]
              result[:family_name] = name[:familyName]
            end
            if name[:type].present? && name[:type][:code].present? && name[:type][:code].upcase == type.upcase
              result[:first_name] = name[:givenName]
              result[:last_name] = name[:familyName]
              result[:person_name] = name[:formattedName]
              found_match = true
            end
          end
        end
      end
      found_match
    end

    def extract_roles(edo, result)
      result[:roles] = roles_from_cs_affiliations(edo[:affiliations])
    end

    def extract_emails(edo, result)
      if edo[:emails].present?
        edo[:emails].each do |email|
          if email[:primary] == true
            result[:email_address] = email[:emailAddress]
          end
          if email[:type].present? && email[:type][:code] == 'CAMP'
            result[:official_bmail_address] = email[:emailAddress]
          end
        end
      end
    end

  end
end
