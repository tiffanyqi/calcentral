module CampusSolutions
  class DelegateStudents < CachedProxy

    include DelegatedAccessFeatureFlagged

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def build_feed(response)
      feed = response.parsed_response
      return {} if feed.blank?
      students = feed['ROOT']['STUDENT_DELEGATED_ACCESS']['STUDENTS'] if feed['ROOT'] && feed['ROOT']['STUDENT_DELEGATED_ACCESS']
      transform_feed students
    end

    def xml_filename
      'delegate_access_students.xml'
    end

    def url
      "#{@settings.base_url}/UC_CC_DELEGATED_ACCESS.v1/DelegatedAccess/get?SCC_DA_PRXY_OPRID=#{@uid}"
    end

    def transform_feed(students)
      return {} if students.nil?
      feed = {}
      students.each do |student|
        transformation = {}
        empl_id = student['EMPLID']
        transformation['campus_solutions_id'] = empl_id
        transformation['uid'] = CalnetCrosswalk::ByCsId.new(user_id: empl_id).lookup_ldap_uid
        transformation['full_name'] = student['NAME']
        transformation['privileges'] = { 'financial' => false, 'view_enrollments' => false, 'view_grades' => false, 'phone' => false }
        if (role_names = student['ROLENAMES'])
          role_names.each do |role_name|
            case role_name.downcase
              when /financial/ then transformation['privileges']['financial'] = true
              when /enrollments_view/ then transformation['privileges']['view_enrollments'] = true
              when /grades/ then transformation['privileges']['view_grades'] = true
              # This corresponds to CS 'Transactions: Phone and In-Person' permission, but is not exposed in CalCentral.
              when /release/ then transformation['privileges']['phone'] = true
            end
          end
        end
        feed['students'] ||= []
        feed['students'] << transformation
      end
      feed
    end
  end
end
