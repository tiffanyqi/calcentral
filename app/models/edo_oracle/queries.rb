module EdoOracle
  class Queries < Connection
    include ActiveRecordHelper

    CANONICAL_SECTION_ORDERING = 'dept_name, catalog_root, catalog_prefix nulls first, catalog_suffix nulls first, primary, instruction_format, display_name, section_num'

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
          enr."UNITS_TAKEN" AS unit,
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
    def self.get_instructing_sections(person_id, terms = nil)
      result = []
      terms_list = terms.map { |term| "'#{term.campus_solutions_id}'" }.join ','
      use_pooled_connection do
        sql = <<-SQL
        SELECT
          #{SECTION_COLUMNS}
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

  end
end
