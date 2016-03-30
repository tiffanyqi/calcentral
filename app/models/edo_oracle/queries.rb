module EdoOracle
  class Queries < Connection
    include ActiveRecordHelper

    CANONICAL_SECTION_ORDERING = 'dept_name, catalog_root, catalog_prefix nulls first, catalog_suffix nulls first, primary DESC, instruction_format, display_name, section_num'

    # Changes from CampusOracle::Queries section columns:
    #   - 'course_cntl_num' now 'section_id'
    #   - 'term_yr' and 'term_cd' replaced by 'term_id'
    #   - 'catalog_suffix_1' and 'catalog_suffix_2' replaced by 'catalog_suffix' (combined)
    #   - 'primary_secondary_cd' replaced by Boolean 'primary'
    #   - 'display_name' added
    SECTION_COLUMNS = <<-SQL
      sec."id" AS section_id,
      sec."term-id" AS term_id,
      TRIM(crs."title") AS course_title,
      TRIM(crs."transcriptTitle") AS course_title_short,
      crs."academicDepartment-descr" AS dept_name,
      sec."primary" AS primary,
      sec."sectionNumber" AS section_num,
      sec."component-code" as instruction_format,
      sec."primaryAssociatedSectionId" as primary_associated_section_id,
      crs."displayName" AS display_name,
      crs."catalogNumber-formatted" AS catalog_id,
      crs."catalogNumber-number" AS catalog_root,
      crs."catalogNumber-prefix" AS catalog_prefix,
      crs."catalogNumber-suffix" AS catalog_suffix
    SQL

    # EDO equivalent of CampusOracle::Queries.get_enrolled_sections
    # Changes:
    #   - 'wait_list_seq_num' replaced by 'waitlist_position'
    #   - 'course_option' removed
    #   - 'cred_cd' and 'pnp_flag' replaced by 'grading_basis'
    def self.get_enrolled_sections(person_id, terms = nil)
      result = []
      terms_list = terms.map { |term| "'#{term.campus_solutions_id}'" }.join ','
      use_pooled_connection do
        sql = <<-SQL
        SELECT
          #{SECTION_COLUMNS},
          sec."maxEnroll" AS enroll_limit,
          enr."STDNT_ENRL_STATUS_CODE" AS enroll_status,
          enr."WAITLISTPOSITION" AS waitlist_position,
          enr."UNITS_TAKEN" AS units,
          enr."GRADE_MARK" AS grade,
          enr."GRADING_BASIS_CODE" AS grading_basis
        FROM SISEDO.ENROLLMENTV00_VW enr
        JOIN SISEDO.CLASSSECTIONV00_VW sec ON (
          enr."TERM_ID" = sec."term-id" AND
          enr."SESSION_ID" = sec."session-id" AND
          enr."CLASS_SECTION_ID" = sec."id")
        LEFT OUTER JOIN SISEDO.API_COURSEV00_VW crs ON (sec."displayName" = crs."displayName")
        WHERE (crs."status-code" = 'ACTIVE' OR crs."status-code" IS NULL)
          AND sec."status-code" = 'A'
          AND sec."term-id" IN (#{terms_list})
          AND enr."CAMPUS_UID" = '#{person_id}'
        ORDER BY term_id DESC, #{CANONICAL_SECTION_ORDERING}
        SQL
        result = connection.select_all sql
      end
      stringify_ints! result
    end

    # EDO equivalent of CampusOracle::Queries.get_instructing_sections
    # Changes:
    #   - 'cs-course-id' added.
    def self.get_instructing_sections(person_id, terms = nil)
      result = []
      terms_list = terms.map { |term| "'#{term.campus_solutions_id}'" }.join ','
      use_pooled_connection do
        sql = <<-SQL
        SELECT
          #{SECTION_COLUMNS},
          sec."cs-course-id" AS cs_course_id
        FROM SISEDO.ASSIGNEDINSTRUCTORV00_VW instr
        JOIN SISEDO.CLASSSECTIONV00_VW sec ON (
          instr."term-id" = sec."term-id" AND
          instr."session-id" = sec."session-id" AND
          instr."cs-course-id" = sec."cs-course-id" AND
          instr."offeringNumber" = sec."offeringNumber" AND
          instr."number" = sec."sectionNumber")
        LEFT OUTER JOIN SISEDO.API_COURSEV00_VW crs ON (sec."displayName" = crs."displayName")
        WHERE (crs."status-code" = 'ACTIVE' OR crs."status-code" IS NULL)
          AND sec."status-code" = 'A'
          AND instr."term-id" IN (#{terms_list})
          AND instr."campus-uid" = '#{person_id}'
        ORDER BY term_id DESC, #{CANONICAL_SECTION_ORDERING}
        SQL
        result = connection.select_all sql
      end
      stringify_ints! result
    end

    # EDO equivalent of CampusOracle::Queries.get_secondary_sections.
    # Changes:
    #   - More precise associations allow us to query by primary section rather
    #     than course catalog ID.
    #   - 'cs-course-id' added.
    def self.get_associated_secondary_sections(term_id, section_id)
      result = []
      use_pooled_connection do
        sql = <<-SQL
        SELECT
          #{SECTION_COLUMNS},
          sec."cs-course-id" AS cs_course_id
        FROM SISEDO.CLASSSECTIONV00_VW sec
        LEFT OUTER JOIN SISEDO.API_COURSEV00_VW crs ON (sec."displayName" = crs."displayName")
        WHERE (crs."status-code" = 'ACTIVE' OR crs."status-code" IS NULL)
          AND sec."status-code" = 'A'
          AND sec."primary" = 'false'
          AND sec."term-id" = '#{term_id}' AND
          AND sec."primaryAssociatedSectionId" = '#{section_id}'
        ORDER BY #{CANONICAL_SECTION_ORDERING}
        SQL
        result = connection.select_all sql
      end
      stringify_ints! result
    end

    # EDO equivalent of CampusOracle::Queries.get_section_schedules
    # Changes:
    #   - 'course_cntl_num' is replaced with 'section_id'
    #   - 'term_yr' and 'term_cd' replaced by 'term_id'
    #   - 'session_id' added
    #   - 'building_name' and 'room_number' combined as 'location'
    #   - 'meeting_start_time_ampm_flag' is included in 'meeting_start_time' timestamp
    #   - 'meeting_end_time_ampm_flag' is included in 'meeting_end_time' timestamp
    #   - 'multi_entry_cd' obsolete now that multiple meetings directly associated with section
    #   - 'print_cd' replaced with 'print_in_schedule_of_classes' boolean
    def self.get_section_meetings(term_id, section_id)
      results = []
      use_pooled_connection {
        sql = <<-SQL
        SELECT
          sec."id" AS section_id,
          sec."printInScheduleOfClasses" AS print_in_schedule_of_classes,
          mtg."term-id" AS term_id,
          mtg."session-id" AS session_id,
          mtg."location-code" AS location,
          mtg."meetsDays" AS meeting_days,
          mtg."startTime" AS meeting_start_time,
          mtg."endTime" AS meeting_end_time
        FROM
          SISEDO.MEETINGV00_VW mtg
        LEFT OUTER JOIN SISEDO.CLASSSECTIONV00_VW sec ON (
            mtg."cs-course-id" = sec."cs-course-id" AND
            mtg."term-id" = sec."term-id" AND
            mtg."session-id" = sec."session-id" AND
            mtg."offeringNumber" = sec."offeringNumber" AND
            mtg."sectionNumber" = sec."sectionNumber"
          )
        WHERE
          sec."printInScheduleOfClasses" = 'Y' AND
          sec."term-id" = '#{term_id}' AND
          sec."id" = '#{section_id}' AND
          mtg."location-code" IS NOT NULL
        ORDER BY
          mtg."sectionNumber" ASC
        SQL
        results = connection.select_all(sql)
      }
      stringify_ints! results
    end

    # EDO equivalent of CampusOracle::Queries.get_sections_from_ccns
    def self.get_sections_by_ids(term_id, section_ids)
      result = {}
      use_pooled_connection {
        sql = <<-SQL
        SELECT
          #{SECTION_COLUMNS}
        FROM SISEDO.CLASSSECTIONV00_VW sec
        LEFT OUTER JOIN SISEDO.API_COURSEV00_VW crs ON (sec."displayName" = crs."displayName")
        WHERE (crs."status-code" = 'ACTIVE' OR crs."status-code" IS NULL)
          AND sec."term-id" = '#{term_id}'
          AND sec."id" IN (#{section_ids.collect { |id| id.to_i }.join(', ')})
        ORDER BY #{CANONICAL_SECTION_ORDERING}
        SQL
        result = connection.select_all(sql)
      }
      stringify_ints!(result)
    end

    # EDO equivalent of CampusOracle::Queries.get_section_instructors
    # Changes:
    #   - 'ccn' replaced by 'section_id' argument
    #   - 'term_yr' and 'term_cd' replaced by 'term_id'
    #   - 'instructor_func' has become represented by 'role_code' and 'role_description'
    #   - Does not provide all user profile fields ('email_address', 'student_id', 'affiliations').
    #     This will require a programmatic join at a higher level.
    #     See CLC-6239 for implementation of batch LDAP profile requests.
    #
    # TODO: Update CanvasCsv::SiteMembershipsMaintainer to merge user profile data into this feed.
    def self.get_section_instructors(term_id, section_id)
      results = []
      use_pooled_connection {
        sql = <<-SQL
          SELECT
            TRIM(instr."formattedName") AS person_name,
            TRIM(instr."givenName") AS first_name,
            TRIM(instr."familyName") AS last_name,
            instr."campus-uid" AS ldap_uid,
            instr."role-code" AS role_code,
            instr."role-descr" AS role_description
          FROM
            SISEDO.ASSIGNEDINSTRUCTORV00_VW instr
          LEFT OUTER JOIN SISEDO.CLASSSECTIONV00_VW sec ON (
            instr."cs-course-id" = sec."cs-course-id" AND
            instr."term-id" = sec."term-id" AND
            instr."session-id" = sec."session-id" AND
            instr."offeringNumber" = sec."offeringNumber" AND
            instr."number" = sec."number"
          )
          WHERE
            sec."id" = '#{section_id.to_s}' AND
            sec."term-id" = '#{term_id.to_s}'
          ORDER BY
            role_code
        SQL
        results = connection.select_all(sql)
      }
      stringify_ints! results
    end

    # EDO equivalent of CampusOracle::Queries.terms
    # Changes:
    #   - 'term_yr' and 'term_cd' replaced by 'term_id'
    #   - 'term_status', 'term_status_desc', and 'current_tb_term_flag' are not present.
    #     No indication of past, current, or future term status
    #   - Multiple entries for each term due to differing start and end dates that
    #     may exist for LAW as compared to GRAD, UGRAD, or UCBX
    def self.terms
      result = []
      use_pooled_connection {
        sql = <<-SQL
        SELECT
          term."STRM" as term_code,
          trim(term."DESCR") AS term_name,
          term."TERM_BEGIN_DT" AS term_start_date,
          term."TERM_END_DT" AS term_end_date
        FROM
          SISEDO.TERM_TBL_VW term
        ORDER BY
          term_start_date desc
        SQL
        result = connection.select_all(sql)
      }
      result
    end

  end
end
