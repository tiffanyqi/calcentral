module MyAcademics
  class GpaUnits
    include AcademicsModule
    include ClassLogger
    include User::Student

    def merge(data)
      gpa = hub_gpa_units
      prefer_legacy_data = Settings.features.cs_academic_profile_prefers_legacy
      if (current_term.legacy? || prefer_legacy_data) && legacy_student?
        legacy_gpa = oracle_gpa_units
        if gpa[:empty] || (prefer_legacy_data && !legacy_gpa[:empty])
          gpa = legacy_gpa
        end
      end
      data[:gpaUnits] = gpa
    end

    def hub_gpa_units
      response = HubEdos::AcademicStatus.new(user_id: @uid).get
      # response is a pointer to an obj in memory and should not be modified, other functions may need to use it later
      result = response.clone
      if (status = parse_hub_academic_status result)
        # GPA is passed as a string to force a decimal point for whole values.
        result[:cumulativeGpa] = (cumulativeGpa = parse_hub_cumulative_gpa status) && cumulativeGpa.to_s
        result[:totalUnits] = (totalUnits = parse_hub_total_units status) && totalUnits.to_f
        result[:totalUnitsAttempted] = (totalUnitsAttempted = parse_hub_total_units_attempted status) && totalUnitsAttempted.to_f
      else
        result[:empty] = true
      end
      result.delete(:feed)
      result
    end

    def parse_hub_cumulative_gpa(status)
      status['cumulativeGPA'].try(:[], 'average')
    end

    def parse_hub_total_units(status)
      if (units = status['cumulativeUnits']) && (total_units = units.find { |u| u['type'] && u['type']['code'] == 'Total'})
        total_units['unitsPassed']
      end
    end

    def parse_hub_total_units_attempted(status)
      if (units = status['cumulativeUnits']) && (total_units = units.find { |u| u['type'] && u['type']['code'] == 'For GPA'})
        total_units['unitsTaken']
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
