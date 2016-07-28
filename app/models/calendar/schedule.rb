module Calendar
  module Schedule

    # Logic common to all data sources.
    module Common
      def build_schedule(meeting, recurrence)
        {}.tap do |schedule|
          if meeting
            schedule[:start] = serialize_datetime meeting[:start]
            schedule[:end] = serialize_datetime meeting[:end]
          end
          if recurrence
            rrule = "RRULE:#{recurrence.value_ical}"
            logger.info "Class Recurrence Rule: #{rrule}"
            schedule[:recurrence] = Array.wrap rrule
          end
        end
      end

      def serialize_datetime(datetime)
        {
          dateTime: datetime.rfc3339(3),
          timeZone: Time.zone.tzinfo.name
        }
      end
    end

    # For meeting data sourced from EDO DB.
    module EdoOracle
      extend Common
      extend self
      include ClassLogger

      def from_meeting_data(meeting_data)
        logger.info "Meeting data from EdoOracle: #{meeting_data}"

        first_class_meeting = get_first_class_meeting meeting_data
        recurrence = get_recurrence meeting_data
        build_schedule(first_class_meeting, recurrence)
      end

      def get_first_class_meeting(row)
        %w(meeting_start_date meeting_start_time meeting_days).each do |k|
          return nil unless row[k].present?
        end
        meeting_on_or_after = row['meeting_start_date'].to_date
        first_meeting_date = meeting_on_or_after

        until row['meeting_days'].include?(first_meeting_date.strftime('%a').upcase[0..1])
          first_meeting_date = first_meeting_date.next
          # If we've iterated through the whole week and not found a match, row['meeting_days'] isn't parseable.
          return nil if first_meeting_date == meeting_on_or_after + 7
        end
        {
          start: parse_datetime(first_meeting_date, row['meeting_start_time']),
          end: parse_datetime(first_meeting_date, row['meeting_end_time'])
        }
      end

      def get_recurrence(row)
        %w(meeting_start_date meeting_end_date meeting_days).each do |k|
          return nil unless row[k].present?
        end
        if row['meeting_start_date'] != row['meeting_end_date']
          Icalendar::Values::Recur.new('').tap do |rrule|
            rrule.by_day = row['meeting_days'].chars.each_slice(2).map &:join
            rrule.frequency = 'WEEKLY'
            rrule.until = "#{row['meeting_end_date'].strftime Icalendar::Values::DateTime::FORMAT}Z"
          end
        end
      end

      def parse_datetime(date, time)
        Time.zone.parse("#{date} #{time}").to_datetime
      end
    end

    # For meeting data sourced from legacy Oracle.
    module CampusOracle
      extend Common
      extend self
      include ClassLogger

      def from_meeting_data(meeting_data)
        return nil unless (term = term_from_row meeting_data)
        logger.info "Meeting data from Oracle: #{meeting_data}; term start: #{term.classes_start}, term end of classes: #{term.classes_end}"

        first_class_meeting = get_first_class_meeting(meeting_data, term)
        recurrence = get_recurrence(meeting_data, term)

        build_schedule(first_class_meeting, recurrence)
      end

      def term_from_row(row)
        slug = Berkeley::TermCodes.to_slug(row['term_yr'], row['term_cd'])
        term = Berkeley::Terms.fetch.campus[slug]
        if term.blank?
          logger.error "Could not determine term #{slug} for course #{row['term_yr']}-#{row['term_cd']}-#{row['course_cntl_num']}"
          return nil
        end
        if term.is_summer
          term = Berkeley::SummerSubTerm.where(year: row['term_yr'], sub_term_code: row['sub_term_cd']).first
          if term.blank?
            logger.error "Could not determine subterm #{row['sub_term_cd']} for course #{row['term_yr']}-#{row['term_cd']}-#{row['course_cntl_num']}"
            return nil
          end
        end
        term
      end

      def get_first_class_meeting(row, term)
        %w(meeting_days meeting_start_time meeting_start_time_ampm_flag meeting_end_time meeting_end_time_ampm_flag).each do |k|
          return nil unless row[k].present?
        end

        # Check for a first meeting the same week as start of instruction.
        first_meeting_wday = iterate_meeting_days(row).find_index do |c, i|
          c.present? && (i >= term.classes_start.wday)
        end

        # If not found, set a first meeting the week after start of instruction.
        unless first_meeting_wday
          first_meeting_wday = iterate_meeting_days(row).find_index do |c, i|
            c.present?
          end
          first_meeting_wday += 7
        end

        first_meeting = term.classes_start + (first_meeting_wday - term.classes_start.wday)

        times = {
          start: advance_time(first_meeting, row['meeting_start_time'], row['meeting_start_time_ampm_flag']),
          end: advance_time(first_meeting, row['meeting_end_time'], row['meeting_end_time_ampm_flag'])
        }
        logger.info "Class Meeting Times: #{times}"
        times
      end

      def advance_time(time_start, time, ampm_flag)
        time_stripped = time.gsub(/^0/, '')
        minute = time_stripped.slice!(-2, 2).to_i
        hour = time_stripped.to_i
        if hour < 12 && ampm_flag == 'P'
          hour += 12
        end
        time_start.change(hour: hour, min: minute)
      end

      WEEKDAYS = %w(SU MO TU WE TH FR SA)

      def get_recurrence(row, term)
        meeting_weekdays = []
        iterate_meeting_days(row).each do |c, i|
          meeting_weekdays << WEEKDAYS[i] if c.present?
        end
        if meeting_weekdays.any?
          Icalendar::Values::Recur.new('').tap do |rrule|
            rrule.by_day = meeting_weekdays
            rrule.frequency = 'WEEKLY'
            rrule.until = "#{term.classes_end.utc.strftime Icalendar::Values::DateTime::FORMAT}Z"
          end
        end
      end

      def iterate_meeting_days(row)
        # Legacy Oracle indicates meeting days by strings such as ' M W F' or '  T T'. Iterate characters with index.
        row['meeting_days'].to_s.each_char.with_index
      end
    end

  end
end
