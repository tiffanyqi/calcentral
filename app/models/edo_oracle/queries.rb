module EdoOracle
  class Queries < Connection
    include ActiveRecordHelper

    def self.get_instructing_sections(person_id, terms = nil)
      result = []
      terms_list = terms.map { |term| "'#{term.campus_solutions_id}'" }.join ','
      use_pooled_connection do
        sql = <<-SQL
        SELECT
          crs."title" AS title,
          TRIM(crs."transcriptTitle") AS transcript_title,
          TRIM(crs."description") AS description,
          crs."subjectArea" AS dept_name,
          crs."catalogNumber-number" AS catalog_root,
          crs."catalogNumber-prefix" AS catalog_prefix,
          crs."catalogNumber-suffix" AS catalog_suffix,
          sec."term-id" AS term_id,
          sec."id" AS section_id,
          sec."displayName" AS display_name,
          sec."primary" AS primary_secondary_cd,
          sec."component-code" AS instruction_format,
          sec."sectionNumber" AS section_num
        FROM SISEDO.ASSIGNEDINSTRUCTORV00_VW instr
        JOIN SISEDO.CLASSSECTIONV00_VW sec ON (
          instr."term-id" = sec."term-id" AND
          instr."session-id" = sec."session-id" AND
          instr."cs-course-id" = sec."cs-course-id" AND
          instr."offeringNumber" = sec."offeringNumber" AND
          instr."number" = sec."sectionNumber")
        LEFT OUTER JOIN SISEDO.API_COURSEV00_VW crs ON (sec."displayName" = crs."displayName")
        WHERE (crs."status-code" = 'ACTIVE' OR crs."status-code" IS NULL)
          AND instr."term-id" IN (#{terms_list})
          AND instr."campus-uid" = '#{person_id}'
        ORDER BY term_id DESC, display_name, section_num
        SQL
        result = connection.select_all sql
      end
      stringify_ints! result
    end

    def self.get_sections_from_section_ids(term_yr, term_cd, section_ids)
      edo_term_id = Berkeley::TermCodes.to_edo_id(term_yr, term_cd)
      result = {}
      use_pooled_connection {
        sql = <<-SQL
        SELECT sec."id" as section_id, sec."primary" as primary_secondary_cd,  sec."sectionNumber" as section_num, sec."component-code" as instruction_format,
          crs."title" AS course_title, crs."transcriptTitle" AS course_title_short, crs."academicDepartment-descr" as dept_name,
          crs."catalogNumber-formatted" as catalog_id, sec."term-id" as term_id, crs."catalogNumber-number" as catalog_root,
          crs."catalogNumber-prefix" as catalog_prefix, crs."catalogNumber-suffix" as catalog_suffix
        FROM SISEDO.CLASSSECTIONV00_VW sec
        LEFT OUTER JOIN SISEDO.API_COURSEV00_VW crs ON (sec."displayName" = crs."displayName")
        LEFT OUTER JOIN SISEDO.CLASSV00_VW cls ON (sec."displayName" = cls."displayName" AND sec."term-id" = cls."term-id" AND sec."session-id" = cls."session-id" AND sec."offeringNumber" = cls."offeringNumber")
        WHERE crs."status-code" = 'ACTIVE' AND cls."term-id" = '#{edo_term_id}' AND sec."id" IN (#{section_ids.collect { |id| id.to_i }.join(', ')})
        ORDER BY dept_name, catalog_root, catalog_prefix nulls first, catalog_suffix nulls first, primary_secondary_cd, instruction_format, section_num
        SQL
        result = connection.select_all(sql)
      }
      stringify_ints!(result)
    end

  end
end
