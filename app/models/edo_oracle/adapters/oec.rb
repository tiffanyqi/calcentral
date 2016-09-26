module EdoOracle
  module Adapters
    class Oec
      extend EdoOracle::Adapters::Common

      def self.adapt_courses(rows, term_code)
        default_dates = get_default_dates term_code
        user_courses = EdoOracle::UserCourses::Base.new
        supplement_email_addresses rows

        rows.each do |row|
          uniq_ccn_lists row

          adapt_dept_name_and_catalog_id(row, user_courses)
          adapt_course_name row

          adapt_course_cntl_num row
          adapt_course_id(row, term_code)
          adapt_cross_listed_flag row
          adapt_dates(row, default_dates)
          adapt_evaluation_type row
          adapt_instructor_func row
          adapt_primary_secondary_cd row
          adapt_sis_id row

          row['blue_role'] = '23'
        end
      end

      def self.adapt_enrollments(rows, term_code)
        supplement_email_addresses rows
        rows.each do |row|
          adapt_course_id(row, term_code)
        end
      end

      def self.supplement_email_addresses(rows)
        rows_without_email = rows.inject({}) do |hash, row|
          # Check for the presence of the email_address key because not all queries are expected to return email addresses.
          if row['ldap_uid'].present? && row.has_key?('email_address') && row['email_address'].blank?
            hash[row['ldap_uid']] ||= []
            hash[row['ldap_uid']] << row
          end
          hash
        end
        User::BasicAttributes.attributes_for_uids(rows_without_email.keys).each do |attrs|
          rows_without_email[attrs[:ldap_uid]].each do |row|
            row['email_address'] = attrs[:email_address]
          end
        end
      end

      def self.get_default_dates(term_code)
        slug = Berkeley::TermCodes.to_slug *term_code.split('-')
        term = Berkeley::Terms.fetch.campus[slug]
        {
          start: term.classes_start.to_date,
          end: term.instruction_end.to_date
        }
      end

      def self.adapt_course_id(row, term_code)
        if row['section_id']
          row['course_id'] = "#{term_code}-#{row.delete 'section_id'}"
        end
      end

      def self.adapt_course_name(row)
        if row['dept_name']
          row['course_name'] = row.values_at('dept_name', 'catalog_id', 'instruction_format', 'section_num', 'course_title_short').join ' '
        end
      end

      def self.adapt_cross_listed_flag(row)
        row['cross_listed_flag'] = 'Y' if row['cross_listed_ccns'].present?
      end

      def self.adapt_dates(row, default_dates)
        if (row['start_date'] && row['end_date'])
          if (row['start_date'].to_date == default_dates[:start] && row['end_date'].to_date == default_dates[:end])
            row.delete 'start_date'
            row.delete 'end_date'
          else
            row['modular_course'] = 'Y'
            row['start_date'] = row['start_date'].strftime ::Oec::Worksheet::WORKSHEET_DATE_FORMAT
            row['end_date'] = row['end_date'].strftime ::Oec::Worksheet::WORKSHEET_DATE_FORMAT
          end
        end
      end

      def self.adapt_evaluation_type(row)
        row['evaluation_type'] = case row['affiliations']
                                   when /STUDENT/ then 'G'
                                   when /INSTRUCTOR/ then 'F'
                                 end
      end

      def self.adapt_sis_id(row)
        unless row['affiliations'] && row['affiliations'].include?('STUDENT')
          row['sis_id'] = row['ldap_uid'] ? "UID:#{row['ldap_uid']}" : nil
        end
      end

      def self.uniq_ccn_lists(row)
        %w(co_scheduled_ccns cross_listed_ccns).each do |key|
          next unless row[key].present?
          ccns = row[key].split(',').uniq
          if ccns.count > 1
            row[key] = ccns.join(',')
          else
            row.delete key
          end
        end
      end

    end
  end
end
