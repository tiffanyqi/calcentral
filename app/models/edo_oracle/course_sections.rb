module EdoOracle
  class CourseSections < BaseProxy
    include QueryCaching

    def initialize(term_id, course_id)
      super(Settings.edodb)
      @term_id = term_id
      @course_id = course_id
    end

    def get_section_data
      cached_query "#{@course_id}-#{@term_id}" do
        {
          instructors: get_section_instructors,
          schedules: get_section_schedules
        }
      end
    end

    private

    def get_section_schedules
      schedules = EdoOracle::Queries.get_section_meetings(@term_id, @course_id).map do |meeting|
        if meeting && meeting['meeting_days'].present?
          translate_location(meeting).merge(translate_schedule(meeting))
        end
      end
      schedules.compact
    end

    def get_section_instructors
      instructors = EdoOracle::Queries.get_section_instructors(@term_id, @course_id).map do |instructor|
        {
          name: instructor['person_name'],
          role: instructor['role_code'],
          uid: instructor['ldap_uid']
        }
      end
      instructors.uniq
    end

    def strip_leading_zeros(str=nil)
      (str.nil?) ? nil : "#{str}".gsub!(/^[0]*/, '')
    end

    def translate_location(meeting)
      return {} unless meeting['location']
      location_chunks = meeting['location'].rpartition /\s+/
      if location_chunks.first.present?
        {
          buildingName: location_chunks.first,
          roomNumber: strip_leading_zeros(location_chunks.last)
        }
      else
        {
          buildingName: location_chunks.last,
          roomNumber: ''
        }
      end
    end

    def translate_schedule(meeting)
      schedule = ''
      if meeting['meeting_days'].present?
        meeting['meeting_days'].chars.each_slice(2).inject(schedule) do |schedule, day_chars|
          schedule << case day_chars.join
            when 'SU' then 'Su'
            when 'MO' then 'M'
            when 'TU' then 'Tu'
            when 'WE' then 'W'
            when 'TH' then 'Th'
            when 'FR' then 'F'
            when 'SA' then 'Sa'
            else ''
          end
        end
      end
      if meeting['meeting_start_time'].present?
        schedule << " #{meeting['meeting_start_time']}"
        schedule << "-#{meeting['meeting_end_time']}" unless meeting['meeting_end_time'].blank?
      end
      {
        schedule: schedule
      }
    end

  end
end
