module EdoOracle
  class Calendar < EdoOracle::Connection
    include ActiveRecordHelper

    def self.get_all_courses
      term_ids = get_campus_solutions_term_ids
      safe_query <<-SQL
        SELECT DISTINCT
          mtg."term-id" AS term_id,
          mtg."session-id" AS session_id,
          sec."id" AS section_id,
          sec."displayName" AS section_display_name,
          sec."component-code" as instruction_format,
          sec."sectionNumber" AS section_num,
          mtg."number" AS meeting_num,
          mtg."location-descr" AS location,
          mtg."meetsDays" AS meeting_days,
          mtg."startTime" AS meeting_start_time,
          mtg."endTime" AS meeting_end_time,
          mtg."startDate" AS meeting_start_date,
          mtg."endDate" AS meeting_end_date
        FROM
          SISEDO.MEETINGV00_VW mtg
          JOIN SISEDO.CLASSSECTIONV00_VW sec ON (
          mtg."cs-course-id" = sec."cs-course-id" AND
          mtg."term-id" = sec."term-id" AND
          mtg."session-id" = sec."session-id" AND
          mtg."offeringNumber" = sec."offeringNumber" AND
          mtg."sectionNumber" = sec."sectionNumber")
        WHERE
          mtg."term-id" IN (#{term_ids.join ','})
        ORDER BY term_id, session_id, section_id, meeting_num
      SQL
    end

    def self.get_whitelisted_students_in_course(users, term_id, course_id)
      return [] if users.blank?
      users_clause = chunked_whitelist('enroll."CAMPUS_UID"', users.map(&:uid))
      safe_query <<-SQL
        SELECT DISTINCT
          enroll."CAMPUS_UID" AS ldap_uid,
          email."EMAIL_EMAILADDRESS" AS official_bmail_address
        FROM SISEDO.ENROLLMENTV00_VW enroll
          LEFT OUTER JOIN SISEDO.PERSON_EMAILV00_VW email ON (
          enroll."STUDENT_ID" = email."PERSON_KEY" AND
          email."EMAIL_TYPE_CODE" = 'CAMP')
        WHERE
          enroll."CLASS_SECTION_ID" = '#{course_id}'
          AND enroll."TERM_ID" = '#{term_id}'
          AND enroll."STDNT_ENRL_STATUS_CODE" != 'D'
          AND #{users_clause}
      SQL
    end

    def self.get_campus_solutions_term_ids
      terms = [
        Berkeley::Terms.fetch.current,
        Berkeley::Terms.fetch.next,
        Berkeley::Terms.fetch.future
      ]
      terms.map { |term| term.campus_solutions_id if term && !term.legacy? }.compact
    end

  end
end
