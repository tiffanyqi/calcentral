module CanvasLti
  module SisAdapter
    extend self

    def get_enrolled_students(section_id, term_year, term_code)
      if Berkeley::Terms.legacy?(term_year, term_code)
        CampusOracle::Queries.get_enrolled_students(section_id, term_year, term_code)
      else
        EdoOracle::Queries.get_enrolled_students(section_id, term_id(term_year, term_code)).tap do |enrollments|
          add_legacy_pnp_flag enrollments
        end
      end
    end

    def get_section_instructors(section_id, term_year, term_code)
      if Berkeley::Terms.legacy?(term_year, term_code)
        CampusOracle::Queries.get_section_instructors(term_year, term_code, section_id)
      else
        instructors = EdoOracle::Queries.get_section_instructors(term_id(term_year, term_code), section_id)
        add_legacy_instructor_func(instructors)
      end
    end

    def get_sections_by_ids(section_ids, term_year, term_code)
      if Berkeley::Terms.legacy?(term_year, term_code)
        CampusOracle::Queries.get_sections_from_ccns(term_year, term_code, section_ids)
      else
        EdoOracle::Queries.get_sections_by_ids(term_id(term_year, term_code), section_ids).tap do |sections|
          add_legacy_ccns sections
          add_legacy_term_fields sections
          add_legacy_primary_secondary_cd sections
          normalize_course_codes sections
        end
      end
    end

    def term_id(term_year, term_code)
      Berkeley::TermCodes.to_edo_id(term_year, term_code)
    end

    def add_legacy_instructor_func(instructors)
      instructors.collect {|instr| instr.merge({'instructor_func' => convert_role_code_to_instructor_func(instr['role_code'])})}
    end

    def convert_role_code_to_instructor_func(role_code)
      case role_code.to_s
        when 'PI' then '1'    # Teaching and In Charge, equivalent of Teaching and Instructor of Record (1)
        when 'TNIC' then '2'  # Teaching but Not in Charge, equivalent of Teaching but not Instructor of Record (2)
        when 'ICNT' then '3'  # In Charge but Not Teaching, equivalent of Not teaching but Instructor of Record (3). Instructors coded as 3 must be accompanied by another "teaching" instructor coded as 2.
        when 'INVT' then '4'  # Teaching with Invalid Title, equivalent of No Valid Teaching Title Code (4)
        else raise ArgumentError, "Unable to convert to 'instructor_func'. No such role code: '#{role_code}'"
      end
    end

    def add_legacy_ccns(sections)
      sections.each {|sec| sec['course_cntl_num'] = sec['section_id']}
    end

    def add_legacy_pnp_flag(enrollments)
      enrollments.each do |enr|
        grade_option = Berkeley::GradeOptions.grade_option_from_basis enr['grading_basis']
        enr['pnp_flag'] = case grade_option
                            when 'P/NP', 'S/U' then 'Y'
                            else 'N'
                          end
      end
    end

    def add_legacy_term_fields(sections)
      sections.each do |sec|
        legacy_term = Berkeley::TermCodes.from_edo_id(sec['term_id'])
        sec.merge!({'term_yr' => legacy_term[:term_yr], 'term_cd' => legacy_term[:term_cd]})
      end
    end

    def add_legacy_primary_secondary_cd(sections)
      sections.each {|sec| sec['primary_secondary_cd'] = sec['primary'] == 'true' ? 'P' : 'S'}
    end

    def normalize_course_codes(sections)
      sections.each do |sec|
        dept_name, catalog_id = EdoOracle::UserCourses::Base.parse_course_code sec
        sec.merge!({'dept_name' => dept_name, 'catalog_id' => catalog_id})
      end
    end

  end
end
