module Calendar
  class Preprocessor

    include ClassLogger, SafeJsonParser

    def initialize
      @settings = Settings.class_calendar
      @users = Calendar::User.all
      @users_with_alternate_email = build_users_with_alternate_email
      logger.warn "#{@users.length} users are on the calendar whitelist"
    end

    def get_entries
      [].tap do |queue|
        add_legacy_entries queue
        add_edo_oracle_entries queue
      end
    end

    private

    # Queue calendar event entries from legacy terms to ship to Google.
    def add_legacy_entries(queue)
      CampusOracle::Calendar.get_all_courses.each do |course_row|
        if (entry = Calendar::QueuedEntry.from_legacy_row course_row)
          enrollments = CampusOracle::Calendar.get_whitelisted_students(@users, course_row['term_yr'], course_row['term_cd'], course_row['course_cntl_num'])
          entry.attendees = user_email_addresses enrollments
          if entry.preprocess
            queue << entry
          end
        end
      end
    end

    # Queue calendar event entries from EDO DB terms to ship to Google.
    def add_edo_oracle_entries(queue)
      EdoOracle::Calendar.get_all_courses.each do |course_row|
        if (entry = Calendar::QueuedEntry.from_edo_row course_row)
          enrollments = EdoOracle::Calendar.get_whitelisted_students(@users, course_row['term_id'], course_row['section_id'])
          entry.attendees = user_email_addresses enrollments
          if entry.preprocess
            queue << entry
          end
        end
      end
    end

    def user_email_addresses(enrollments)
      # Get list of attendee emails, preferring, in order:
      # - the test override table in Postgres (class_calendar_users.alternate_email);
      # - enrollment data;
      # - LDAP lookup.
      emails = []
      enrollments.each do |enrollment|
        email_address = @users_with_alternate_email[enrollment['ldap_uid']] ||
          enrollment['official_bmail_address'] ||
          email_address_from_ldap(enrollment)
        emails << {email: email_address} if email_address
      end
      emails
    end

    def email_address_from_ldap(enrollment)
      # If we do find a match in LDAP, store it in @users_with_alternate_email for the duration of the job.
      if (email_address = CalnetLdap::UserAttributes.new(user_id: enrollment['ldap_uid']).get_feed[:official_bmail_address])
        @users_with_alternate_email[enrollment['ldap_uid']] = email_address
      end
    end

    def build_users_with_alternate_email
      results = {}
      @users.each do |user|
        if user.alternate_email.present?
          results[user.uid] = user.alternate_email
        end
      end
      results
    end

  end
end
