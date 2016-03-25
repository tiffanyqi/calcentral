module EdoOracle
  module UserCourses

    APP_ID = 'Campus'

    class Base < BaseProxy

      def initialize(options = {})
        super(Settings.campusdb, options)
        @uid = @settings.fake_user_id if @fake
        # Non-legacy terms are those after Settings.terms.legacy_cutoff.
        @non_legacy_academic_terms = Berkeley::Terms.fetch.campus.values.reject &:legacy?
      end

      def self.access_granted?(uid)
        !uid.blank?
      end

      def merge_enrollments(campus_classes)
        previous_item = {}
        EdoOracle::Queries.get_enrolled_sections(@uid, @non_legacy_academic_terms).each do |row|
          if (item = row_to_feed_item(row, previous_item))
            item[:role] = 'Student'
            merge_feed_item(item, campus_classes)
            previous_item = item
          end
        end
      end

      def merge_instructing(campus_classes)
        previous_item = {}
        # TODO flag cross-listings
        # TODO get implicitly instructed sections
        EdoOracle::Queries.get_instructing_sections(@uid, @non_legacy_academic_terms).each do |row|
          if (item = row_to_feed_item(row, previous_item))
            item[:role] = 'Instructor'
            merge_feed_item(item, campus_classes)
            previous_item = item
          end
        end
      end

      def merge_feed_item(item, campus_classes)
        semester_key = item.values_at(:term_yr, :term_cd).join '-'
        campus_classes[semester_key] ||= []
        campus_classes[semester_key] << item
      end

      def row_to_feed_item(row, previous_item)
        unless (course_item = new_course_item(row, previous_item))
          previous_item[:sections] << row_to_section_data(row)
          nil
        else
          term_data = Berkeley::TermCodes.from_edo_id(row['term_id']).merge({
            term_id: row['term_id']
          })
          course_name = row['course_title'].present? ? row['course_title'] : row['course_title_short']
          course_data = {
            catid: row['catalog_id'],
            course_catalog: row['catalog_id'],
            dept: row['dept_name'],
            emitter: 'Campus',
            name: course_name,
            sections: [
              row_to_section_data(row)
            ]
          }
          course_item.merge(term_data).merge(course_data)
        end
      end

      def new_course_item(row, previous_item)
        if row.values_at('dept_name', 'catalog_id', 'term_id') != previous_item.values_at(:dept, :catid, :term_id)
          course_ids_from_row row
        end
      end

      # Create IDs for a given course item:
      #   "id" : unique for the UserCourses feed across terms; used by Classes
      #   "slug" : URL-friendly ID without term information; used by Academics
      #   "course_code" : the short course name as displayed in the UX
      def course_ids_from_row(row)
        slug = %w(dept_name catalog_id).map { |key| normalize_to_slug row[key] }.join '-'
        term_code = Berkeley::TermCodes.edo_id_to_code row['term_id']
        {
          course_code: row['display_name'],
          id: "#{slug}-#{term_code}",
          slug: slug
        }
      end

      def normalize_to_slug(str)
        str.downcase.gsub(/[^a-z0-9-]+/, '_')
      end

      def row_to_section_data(row)
        section_data = {
          ccn: row['section_id'].to_s,
          instruction_format: row['instruction_format'],
          is_primary_section: row['primary'],
          section_label: "#{row['instruction_format']} #{row['section_num']}",
          section_number: row['section_num']
        }
        section_data[:units] = row['units'] if row['primary']

        # Grading and waitlist data only apply to enrollment records and will be skipped for instructors.
        if row.include? 'enroll_status'
          section_data[:grade] = row['grade'].strip if row['grade'].present?
          section_data[:grading_basis] = row['grading_basis'] if row['primary']
          if row['enroll_status'] == 'W'
            section_data[:waitlistPosition] = row['waitlist_position'].to_i
            section_data[:enroll_limit] = row['enroll_limit'].to_i
          end
        end
        section_data
      end

      def merge_detailed_section_data(campus_classes)
        campus_classes.each_value do |semester|
          semester.each do |course|
            course[:sections].uniq!
            course[:sections].each do |section|
              section.merge! EdoOracle::CourseSections.new(course[:term_id], section[:ccn]).get_section_data
            end
          end
        end
      end

    end
  end
end
