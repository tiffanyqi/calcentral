module User
  class AuthenticationValidator
    extend Cache::Cacheable
    include Cache::UserCacheExpiry
    include Berkeley::UserRoles
    include ClassLogger

    attr_reader :auth_uid

    def initialize(auth_uid)
      @auth_uid = auth_uid
    end

    def feature_enabled?
      Settings.features.authentication_validator
    end

    def validated_user_id
      if feature_enabled? && cached_held_applicant?
        nil
      else
        @auth_uid
      end
    end

    def cached_held_applicant?
      key = self.class.cache_key @auth_uid
      entry = Rails.cache.read key
      if entry
        logger.debug "Entry is already in cache: #{key}"
        return (entry == NilClass) ? nil : entry
      end
      is_held = held_applicant?
      logger.warn "Held UID #{@auth_uid} will be treated as blank UID" if is_held
      expiration = is_held ? self.class.expires_in('User::AuthenticationValidator::short') : self.class.expires_in
      cached_entry = (is_held.nil?) ? NilClass : is_held
      logger.debug "Cache_key will be #{key}, expiration #{expiration}"
      Rails.cache.write(key,
        cached_entry,
        :expires_in => expiration,
        :force => true)
      is_held
    end

    def held_applicant?
      # Check CalDap affiliations first, since that will generally be faster than an API call.
      # We have a choice between CampusOracle::Queries.get_basic_people_attributes (faster but uncached) and
      # CampusOracle::UserAttributes (slower but cached and quickly re-used on the happy path).
      calnet_attributes = CampusOracle::Queries.get_basic_people_attributes([@auth_uid]).first
      return false if calnet_attributes.present? &&
        calnet_attributes['affiliations'].present? &&
        calnet_attributes['affiliations'] != 'STUDENT-TYPE-NOT-REGISTERED'
      cs_feed = HubEdos::Affiliations.new(user_id: @auth_uid).get
      if cs_feed[:feed] && cs_feed[:feed]['student']
        cs_feed = HashConverter.symbolize cs_feed[:feed]['student']
        applicant_in_process?(cs_feed[:affiliations]) && roles_from_cs_affiliations(cs_feed[:affiliations]).blank?
      else
        # We don't know much about this person, but they're not a held applicant.
        false
      end
    end

    def applicant_in_process?(cs_affiliations)
      cs_affiliations.index { |a| (a[:type][:code] == 'APPLICANT') && (a[:status][:code] == 'ACT') }
    end

  end
end
