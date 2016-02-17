module MyAcademics
  class GpaUnits
    extend Cache::Cacheable
    include AcademicsModule
    include ClassLogger
    include Cache::UserCacheExpiry
    include User::Student

    def merge(data)
      data[:gpaUnits] = self.class.fetch_from_cache @uid do
        if !Settings.features.cs_academic_profile || legacy_user?
          oracle_gpa_units
        else
          hub_gpa_units
        end
      end
    end

    def hub_gpa_units
      response = HubEdos::AcademicStatus.new(user_id: @uid).get
      if (status = parse_hub_academic_status response)
        response[:cumulativeGpa] = parse_hub_cumulative_gpa status
        response[:totalUnits] = parse_hub_total_units status
      else
        response[:empty] = true
      end
      response
    end

    def parse_hub_cumulative_gpa(status)
      status['cumulativeGPA'].try(:[], 'average')
    end

    def parse_hub_total_units(status)
      if (units = status['cumulativeUnits']) && (total_units = units.find { |u| u['type'] && u['type']['code'] == 'Total'})
        total_units['unitsPassed']
      end
    end

    def oracle_gpa_units
      student_info = CampusOracle::Queries.get_student_info(@uid) || {}
      {
        cumulativeGpa: student_info['cum_gpa'].nil? ? nil: student_info['cum_gpa'].to_s,
        totalUnits: student_info['tot_units'].nil? ? nil : student_info['tot_units'].to_f,
        totalUnitsAttempted: student_info['lgr_tot_attempt_unit'].nil? ? nil : student_info['lgr_tot_attempt_unit'].to_f
      }
    end

  end
end
