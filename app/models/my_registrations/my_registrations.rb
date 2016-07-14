module MyRegistrations
  class MyRegistrations < UserSpecificModel

    include Berkeley::UserRoles
    include Cache::CachedFeed
    include Cache::JsonAddedCacher
    include Cache::UserCacheExpiry

    def get_feed_internal
      registrations = get_registrations
      terms = get_terms
      {
        affiliations: registrations['affiliations'] || [],
        terms: terms,
        registrations: match_terms(registrations['registrations'], terms)
      }
    end

    def get_registrations
      registrations = HubEdos::Registrations.new(user_id: @uid).get
      registrations[:feed] || []
    end

    def get_terms
      berkeley_terms = Berkeley::Terms.fetch
      terms = {}
      # ':previous' and ':grading_in_progress' methods are not included here because Campus::Oracle does not keep information prior to the current term.
      # These methods should be added in Spring 2017, once CS will start sending back Fall 2016 data.
      [:current, :running, :sis_current_term, :next, :future].each do |term_method|
        term = berkeley_terms.send term_method
        if term
          terms[term_method] = {id: term.campus_solutions_id, name: term.to_english}
        # Often ':future' will be nil, but during Spring terms, it should send back data for the upcoming Fall semester.
        else
          terms[term_method] = nil
        end
      end
      terms
    end

    private

    # Match registration terms with Berkeley::Terms-defined terms.
    def match_terms(registrations, terms)
      legacy_cutoff = Berkeley::TermCodes.slug_to_edo_id(Settings.terms.legacy_cutoff)
      matched_terms = {}
      terms.each do |key, value|
        next if (value.nil? || matched_terms[value[:id]].present?)
        # Array format due to the possibility of a single term containing multiple academic career registrations
        term_id = value[:id]
        term_registrations = []
        # If the term is less than or equal to Settings.terms.legacy_cutoff, parse it as we would a legacy term.
        if (term_id.to_i <= legacy_cutoff.to_i)
          term_registrations.push parse_legacy_term(key, term_id, value[:name])
        elsif registrations.present?
          registrations.each do |registration|
            if (term_id == registration['term']['id'])
              term_registrations.push(registration)
            end
          end
        end
        matched_terms[term_id] = term_registrations if term_registrations.present?
      end
      matched_terms
    end

    def parse_legacy_term(term_name, term_id, term_english)
      term_code = Berkeley::TermCodes.from_edo_id(term_id)
      result = CampusOracle::Queries.get_person_attributes(@uid, term_code[:term_yr], term_code[:term_cd])
      return if result.nil?
      if result
        result[:reg_status] = Notifications::RegStatusTranslator.new.translate_for_feed result['reg_status_cd']
        result[:reg_status][:education_level] = Notifications::EducLevelTranslator.new.translate result['educ_level']
        result[:reg_status].merge! Berkeley::SpecialRegistrationProgram.attributes_from_code(result['reg_special_pgm_cd'])
        result[:roles] = roles_from_campus_row result
      end
      response = {
        is_legacy: true,
        reg_status: result[:reg_status],
        roles: result[:roles]
      }

      # This logic is only used for transition terms, as shown in MyBadges::StudentInfo
      if (term_transition? && result[:reg_status][:summary] != 'Registered')
        response[:reg_status] = {
            code: " ",
            summary: "Not registered for #{term_english}",
            explanation: nil,
            needsAction: false
        }
      end

      if (term_name == :current || term_name == :running)
        result[:reg_status][:transitionTerm] = true if term_transition?
      end

      HashConverter.camelize response
    end

    def term_transition?
      Berkeley::Terms.fetch.in_term_transition?
    end

  end
end
