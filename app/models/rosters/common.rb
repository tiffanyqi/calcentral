module Rosters
  class Common
    extend Cache::Cacheable

    # Roles used with Canvas SIS Import API
    ENROLL_STATUS_TO_CSV_ROLE = {
      'E' => 'Student',
      'W' => 'Waitlist Student',
      'C' => 'Concurrent Student'
    }

    def initialize(uid, options={})
      @uid = uid
      @course_id = options[:course_id]
      @campus_course_id = @course_id
      @canvas_course_id = @course_id
    end

    def get_feed
      self.class.fetch_from_cache "#{@course_id}-#{@uid}" do
        get_feed_internal
      end
    end

    # Serves rosters in CSV format
    def get_csv
      CSV.generate do |csv|
        csv << ['Name','Student ID','User ID','Role','Email Address','Sections','Majors','Terms in Attendance']
        get_feed[:students].each do |student|
          name = student[:last_name] + ', ' + student[:first_name]
          user_id = student[:login_id]
          student_id = student[:student_id]
          email_address = student[:email]
          role = ENROLL_STATUS_TO_CSV_ROLE[student[:enroll_status]]
          sections = sections_to_name_string(student[:sections])
          terms_in_attendance = student[:terms_in_attendance]
          majors = student[:majors].try(:sort).try(:join, ', ')
          csv << [name, student_id, user_id, role, email_address, sections, majors, terms_in_attendance]
        end
      end
    end

    def photo_data_or_file(student_id)
      return nil unless roster = get_feed
      if (student = roster[:students].find { |stu| stu[:id].to_s == student_id.to_s }) && student[:enroll_status] == 'E'
        photo_feed = Cal1card::Photo.new(student[:login_id]).get_feed
        if photo_feed[:photo]
          {
            size: photo_feed[:length],
            data: photo_feed[:photo]
          }
        end
      end
    end

    def index_by_attribute(array_of_hashes, key)
      Hash[array_of_hashes.map { |s| [s[key], s] }]
    end

    def sections_to_name_string(sections)
      sections.map {|section| section[:name]}.sort.join(', ')
    end

    def get_enrollments(course_id, term_yr, term_cd)
      if Berkeley::Terms.legacy?(term_yr, term_cd)
        CampusOracle::Queries.get_enrolled_students(course_id, term_yr, term_cd).map do |row|
          {
            ldap_uid: row['ldap_uid'],
            student_id: row['student_id'],
            first_name: row['first_name'],
            last_name: row['last_name'],
            email: row['student_email_address'],
            enroll_status: row['enroll_status']
          }
        end
      else
        term_id = Berkeley::TermCodes.to_edo_id(term_yr, term_cd)
        enrollments_by_uid = EdoOracle::Queries.get_rosters(course_id, term_id).group_by { |row| row['ldap_uid'] }
        User::BasicAttributes.attributes_for_uids(enrollments_by_uid.keys).each do |attrs|
          attrs[:email] = attrs.delete :email_address
          attrs[:majors] = enrollments_by_uid[attrs[:ldap_uid]].collect { |e| e['major'] }
          if (enrollment_row = enrollments_by_uid[attrs[:ldap_uid]].first)
            attrs[:terms_in_attendance] = terms_in_attendance_code(enrollment_row['terms_in_attendance_group'], enrollment_row['academic_program_code'])
            attrs[:enroll_status] = enrollment_row['enroll_status']
            attrs[:grade_option] = Berkeley::GradeOptions.grade_option_from_basis enrollment_row['grading_basis']
            attrs[:units] = enrollment_row['units'].to_s
            if enrollment_row['enroll_status'] == 'W'
              attrs[:waitlist_position] = enrollment_row['waitlist_position'].to_i
            end
          end
        end
      end
    end

    def terms_in_attendance_code(terms_in_attendance_group, academic_program_code)
      case academic_program_code.try(:[], 0)
        when 'G', 'L'
          'G'
        when 'X'
          "\u2014"
        when 'U'
          terms_in_attendance_group.try(:[], 1)
        else
          nil
      end
    end

  end
end
