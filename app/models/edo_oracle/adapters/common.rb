module EdoOracle
  module Adapters
    module Common

      def adapt_course_cntl_num(row)
        row['course_cntl_num'] = row['section_id'].to_s
      end

      def adapt_dept_name_and_catalog_id(row, user_courses)
        dept_name, catalog_id = user_courses.parse_course_code row
        row.merge!({'dept_name' => dept_name, 'catalog_id' => catalog_id})
      end

      def adapt_instructor_func(row)
        return unless (code = row.delete 'role_code')
        row['instructor_func'] = case code
          when 'PI' then '1'    # Teaching and In Charge, equivalent of Teaching and Instructor of Record (1)
          when 'TNIC' then '2'  # Teaching but Not in Charge, equivalent of Teaching but not Instructor of Record (2)
          when 'ICNT' then '3'  # In Charge but Not Teaching, equivalent of Not teaching but Instructor of Record (3). Instructors coded as 3 must be accompanied by another "teaching" instructor coded as 2.
          when 'INVT' then '4'  # Teaching with Invalid Title, equivalent of No Valid Teaching Title Code (4)
          else raise ArgumentError, "Unable to convert to 'instructor_func'. No such role code: '#{role_code}'"
        end
      end

      def adapt_pnp_flag(row)
        grade_option = Berkeley::GradeOptions.grade_option_from_basis row['grading_basis']
        row['pnp_flag'] = case grade_option
                            when 'P/NP', 'S/U', 'C/NC' then 'Y'
                            else 'N'
                          end
      end

      def adapt_primary_secondary_cd(row)
        row['primary_secondary_cd'] = row['primary'] == 'true' ? 'P' : 'S'
      end

      def adapt_term(row)
        legacy_term = Berkeley::TermCodes.from_edo_id(row['term_id'])
        row.merge!({'term_yr' => legacy_term[:term_yr], 'term_cd' => legacy_term[:term_cd]})
      end

      def term_id(term_year, term_code=nil)
        unless term_code
          term_year, term_code = term_year.split('-')
        end
        Berkeley::TermCodes.to_edo_id(term_year, term_code)
      end

    end
  end
end
