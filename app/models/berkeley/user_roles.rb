module Berkeley
  module UserRoles
    extend self

    def roles_from_affiliations(affiliations)
      affiliations ||= ''
      {
        :student => affiliations.include?('STUDENT-TYPE-'),
        :registered => affiliations.include?('STUDENT-TYPE-REGISTERED'),
        :exStudent => affiliations.include?('STUDENT-STATUS-EXPIRED'),
        :faculty => affiliations.include?('EMPLOYEE-TYPE-ACADEMIC'),
        :staff => affiliations.include?('EMPLOYEE-TYPE-STAFF'),
        :guest => affiliations.include?('GUEST-TYPE-COLLABORATOR'),
        :concurrentEnrollmentStudent => affiliations.include?('AFFILIATE-TYPE-CONCURR ENROLL')
      }
    end

    def roles_from_campus_row(campus_row)
      roles = roles_from_affiliations(campus_row['affiliations'])
      roles[:expiredAccount] = (campus_row['person_type'] == 'Z')
      roles
    end

    def roles_from_cs_affiliations(cs_affiliations)
      return {} unless cs_affiliations
      result = {roles: {}}

      # TODO We still need to cover staff, guests, concurrent-enrollment students and registration status.
      cs_affiliations.select { |a| a[:status][:code] == 'ACT' }.each do |active_affiliation|
        case active_affiliation[:type][:code]
          when 'ADMT_UX'
            result[:roles][:applicant] = true
          when 'APPLICANT'
            result[:applicant_in_process] = true
          when 'GRADUATE'
            result[:roles][:student] = true
            result[:ug_grad_flag] = 'G'
          when 'INSTRUCTOR'
            result[:roles][:faculty] = true
          when 'ADVISOR'
            result[:roles][:advisor] = true
          when 'STUDENT'
            result[:roles][:student] = true
          when 'UNDERGRAD'
            result[:roles][:student] = true
            result[:ug_grad_flag] = 'U'
        end
      end
      cs_affiliations.select { |a| a[:statusCode] == 'INA' }.each do |inactive_affiliation|
        if !result[:roles][:student] && %w(GRADUATE STUDENT UNDERGRAD).include?(inactive_affiliation[:type][:code])
          result[:roles][:exStudent] = true
        end
      end
      result
    end
  end
end
