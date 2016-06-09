module CampusOracle
  class Calendar < CampusOracle::Connection
    include ActiveRecordHelper

    def self.get_all_courses
      result = []
      this_depts_clause = depts_clause('c', Settings.class_calendar.departments)
      use_pooled_connection {
        sql = <<-SQL
      select
        c.term_yr, c.term_cd, c.course_cntl_num, c.sub_term_cd,
        c.dept_name || ' ' || c.catalog_id || ' ' || c.instruction_format || ' ' || c.section_num AS course_name,
        sched.building_name, sched.room_number, sched.meeting_days, sched.meeting_start_time,
        sched.meeting_start_time_ampm_flag, sched.meeting_end_time, sched.meeting_end_time_ampm_flag,
        sched.multi_entry_cd, sched.print_cd, c.course_cntl_num
      from calcentral_course_info_vw c, calcentral_class_schedule_vw sched
      where c.term_yr = sched.term_yr
        and c.term_cd = sched.term_cd
        and c.course_cntl_num = sched.course_cntl_num
        #{terms_query_clause('c', terms)}
        #{this_depts_clause}
      order by c.course_cntl_num, sched.print_cd asc nulls last, sched.multi_entry_cd
        SQL
        result = connection.select_all(sql)
      }
      result = filter_multi_entry_codes result
      stringify_ints! result
    end

    def self.get_whitelisted_students_in_course(users = [], term_yr, term_cd, ccn)
      # fail safer: don't return results if whitelist is empty
      if users.empty?
        return []
      end

      result = []
      users_clause = chunked_whitelist('r.student_ldap_uid', users.map(&:uid))

      use_pooled_connection {
        sql = <<-SQL
          select p.ldap_uid, p.alternateid AS official_bmail_address
          from calcentral_course_info_vw c, calcentral_class_roster_vw r, calcentral_person_info_vw p
          where r.enroll_status != 'D'
            and r.term_yr = c.term_yr
            and r.term_cd = c.term_cd
            and r.course_cntl_num = c.course_cntl_num
            and r.student_ldap_uid = p.ldap_uid
            and c.term_yr = #{term_yr.to_i}
            and c.term_cd = #{connection.quote(term_cd)}
            and c.course_cntl_num = #{ccn.to_i}
        #{users_clause}
          order by p.ldap_uid
        SQL
        result = connection.select_all(sql)
      }
      stringify_ints! result
    end

    def self.terms
      [
        Berkeley::Terms.fetch.current,
        Berkeley::Terms.fetch.next,
        Berkeley::Terms.fetch.future
      ].select { |term| term && term.legacy? }
    end

  end
end
