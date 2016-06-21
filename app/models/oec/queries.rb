module Oec
  module Queries

    def courses_for_codes(term_code, course_codes, import_all = false)
      return [] unless (filter = depts_clause(course_codes, import_all))
      get_courses(term_code, filter)
    end

    def courses_for_cntl_nums(term_code, ccns)
      return [] unless ccns.present? && (filter = chunked_whitelist(course_ccn_column, ccns))
      get_courses(term_code, filter)
    end

    def students_for_cntl_nums(term_code, ccns)
      return [] unless ccns.present? && (filter = chunked_whitelist(enrollment_ccn_column, ccns))
      get_enrollments(term_code, student_info_clause, filter)
    end

    def enrollments_for_cntl_nums(term_code, ccns)
      return [] unless ccns.present? && (filter = chunked_whitelist(enrollment_ccn_column, ccns))
      get_enrollments(term_code, course_and_ldap_uid_clause, filter)
    end

    # When a method is called on the module, forward to the appropriate extender class depending on term code.
    self.instance_methods.each do |method_name|
      define_singleton_method(method_name) do |*args|
        term_yr, term_cd = args.first.split '-'
        if Berkeley::Terms.legacy?(term_yr, term_cd)
          CampusOracle::Oec.send(method_name, *args)
        else
          EdoOracle::Adapters::Oec.send(method_name, *args)
        end
      end
    end

  end
end
