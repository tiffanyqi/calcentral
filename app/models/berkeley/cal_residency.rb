module Berkeley
  module CalResidency
    extend self
    include ClassLogger

    RESIDENCY_READ_MORE_MESSAGE = 'Visit <a href="http://registrar.berkeley.edu/current_students/residency.html">residency information</a> to learn more.'

    def california_residency_from_campus_row(campus_row)
      fee_resid_cd = campus_row['fee_resid_cd']
      case fee_resid_cd
        when nil, 'E'
          return nil
        when ' ', 'S'
          summary = 'No SLR submitted'
          explanation = RESIDENCY_READ_MORE_MESSAGE
          needs_action = true
        when 'P'
          summary = 'Case pending'
          explanation = RESIDENCY_READ_MORE_MESSAGE
          needs_action = true
        when '1'
          summary = 'SLR started but not completed'
          explanation = RESIDENCY_READ_MORE_MESSAGE
          needs_action = true
        when '2'
          # Repress this message during Fall if the student is in the Fall Program for Freshmen
          return nil if campus_row['role_cd'] == '6'
          summary = 'SLR submitted but documentation pending'
          explanation = RESIDENCY_READ_MORE_MESSAGE
          needs_action = true
        when 'R'
          summary = 'Resident'
          explanation = ''
          needs_action = false
        when 'N'
          summary = 'Non-Resident'
          explanation = RESIDENCY_READ_MORE_MESSAGE
          needs_action = false
        when 'L'
          summary = 'Provisional resident'
          explanation = RESIDENCY_READ_MORE_MESSAGE
          needs_action = false
        else
          logger.warn "Unknown FEE_RESID_CD '#{fee_resid_cd}' for UID #{campus_row['ldap_uid']}"
          summary = "Unknown code \"#{fee_resid_cd}\""
          explanation = RESIDENCY_READ_MORE_MESSAGE
          needs_action = true
      end
      {
        summary: summary,
        explanation: explanation,
        needsAction: needs_action
      }
    end

  end
end
