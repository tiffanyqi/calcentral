module Oec
  module Queries
    extend self

    def courses_for_codes(term_code, course_codes, import_all = false)
      return [] unless (filter = EdoOracle::Oec.depts_clause(course_codes, import_all))
      get_courses(term_code, filter)
    end

    def courses_for_cntl_nums(term_code, ccns)
      return [] unless ccns.present? && (filter = EdoOracle::Oec.chunked_whitelist(EdoOracle::Oec.course_ccn_column, ccns))
      get_courses(term_code, filter)
    end

    def students_for_cntl_nums(term_code, ccns)
      return [] unless ccns.present? && (filter = EdoOracle::Oec.chunked_whitelist(EdoOracle::Oec.enrollment_ccn_column, ccns))
      get_enrollments(term_code, EdoOracle::Oec.student_info_clause, filter)
    end

    def enrollments_for_cntl_nums(term_code, ccns)
      return [] unless ccns.present? && (filter = EdoOracle::Oec.chunked_whitelist(EdoOracle::Oec.enrollment_ccn_column, ccns))
      get_enrollments(term_code, EdoOracle::Oec.course_and_ldap_uid_clause, filter)
    end

    def get_courses(term_code, filter)
      term_id = EdoOracle::Adapters::Oec.term_id term_code
      rows = EdoOracle::Oec.get_courses(term_id, filter)
      EdoOracle::Adapters::Oec.adapt_courses(rows, term_code)
    end

    def get_enrollments(term_code, select_clause, filter)
      term_id = EdoOracle::Adapters::Oec.term_id term_code
      rows = EdoOracle::Oec.get_enrollments(term_id, select_clause, filter)
      EdoOracle::Adapters::Oec.adapt_enrollments(rows, term_code)
    end

  end
end
