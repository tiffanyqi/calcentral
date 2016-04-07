module EdoOracle
  module UserCourses
    class SelectedSections < Base

      def get_selected_sections(term_yr, term_cd, course_ids)
        # Sort to get canonical cache key.
        course_ids = course_ids.sort
        term_id = Berkeley::TermCodes.to_edo_id(term_yr, term_cd)
        cached_query "selected_sections-#{term_id}-#{course_ids.join(',')}" do
          campus_classes = {}
          sections = EdoOracle::Queries.get_sections_by_ids(term_id, course_ids)
          previous_item = {}
          sections.each do |row|
            if (item = row_to_feed_item(row, previous_item))
              merge_feed_item(item, campus_classes)
              previous_item = item
            end
          end
          sort_courses campus_classes
          merge_detailed_section_data campus_classes
          campus_classes
        end
      end

    end
  end
end
