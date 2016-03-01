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
      if roles[:student]
        case campus_row['ug_grad_flag']
          when 'U'
            roles[:undergrad] = true
          when 'G'
            roles[:graduate] = true
        end
      end
      roles[:expiredAccount] = (campus_row['person_type'] == 'Z')
      roles
    end

    def roles_from_cs_affiliations(cs_affiliations)
      return {} unless cs_affiliations
      result = {}

      # TODO We still need to cover staff, guests, concurrent-enrollment students and registration status.
      cs_affiliations.select { |a| a[:status][:code] == 'ACT' }.each do |active_affiliation|
        case active_affiliation[:type][:code]
          when 'ADMT_UX'
            result[:applicant] = true
          when 'GRADUATE'
            result[:student] = true
            result[:graduate] = 'G'
          when 'INSTRUCTOR'
            result[:faculty] = true
          when 'ADVISOR'
            result[:advisor] = true
          when 'STUDENT'
            result[:student] = true
          when 'UNDERGRAD'
            result[:student] = true
            result[:undergrad] = 'U'
        end
      end
      cs_affiliations.select { |a| a[:status][:code] == 'INA' }.each do |inactive_affiliation|
        if !result[:student] && %w(GRADUATE STUDENT UNDERGRAD).include?(inactive_affiliation[:type][:code])
          result[:exStudent] = true
        end
      end
      result
    end
  end
end
