module Oec
  module Queries
    extend self

    def courses_for_codes(term_code, course_codes, import_all = false)
      return [] unless (filter = depts_clause(course_codes, import_all))
      EdoOracle::Adapters::Oec.get_courses(term_code, filter)
    end

    def courses_for_cntl_nums(term_code, ccns)
      return [] unless ccns.present? && (filter = chunked_whitelist(EdoOracle::Oec.course_ccn_column, ccns))
      EdoOracle::Adapters::Oec.get_courses(term_code, filter)
    end

    def students_for_cntl_nums(term_code, ccns)
      return [] unless ccns.present? && (filter = chunked_whitelist(EdoOracle::Oec.enrollment_ccn_column, ccns))
      EdoOracle::Adapters::Oec.get_enrollments(term_code, student_info_clause, filter)
    end

    def enrollments_for_cntl_nums(term_code, ccns)
      return [] unless ccns.present? && (filter = chunked_whitelist(EdoOracle::Oec.enrollment_ccn_column, ccns))
      EdoOracle::Adapters::Oec.get_enrollments(term_code, course_and_ldap_uid_clause, filter)
    end

  end
end
