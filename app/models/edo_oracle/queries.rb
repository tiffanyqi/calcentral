module EdoOracle
  class Queries < Connection
    include ActiveRecordHelper

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
