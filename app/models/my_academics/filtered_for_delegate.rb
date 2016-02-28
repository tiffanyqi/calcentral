module MyAcademics
  class FilteredForDelegate < UserSpecificModel

    include Cache::CachedFeed
    include Cache::JsonAddedCacher
    include CampusSolutions::DelegatedAccessFeatureFlagged
    include MergedModel

    def self.providers
      [
        CollegeAndLevel,
        TransitionTerm,
        GpaUnits,
        Semesters,
        Exams
      ]
    end

    def get_feed_as_json(force_cache_write=false)
      if show_grades?
        super(force_cache_write)
      else
        feed = get_feed(force_cache_write)
        filter_grades feed
        feed.to_json
      end
    end

    def get_feed_internal
      return {} unless is_feature_enabled
      feed = {
        filteredForDelegate: true
      }
      handling_provider_exceptions(feed, self.class.providers) do |provider|
        provider.new(@uid).merge feed
      end
      feed
    end

    private

    def filter_grades(feed)
      return unless feed && feed[:semesters]
      feed[:semesters].each do |semester|
        semester[:classes].each do |course|
          [:sections, :transcript].each do |key|
            course[key].each { |section| section.delete :grade } if course[key]
          end
        end
      end
      feed[:gpaUnits].delete :cumulativeGpa
    end

    def show_grades?
      response = CampusSolutions::DelegateStudents.new(user_id: authentication_state.original_delegate_user_id).get
      if response[:feed] && (students = response[:feed][:students])
        campus_solutions_id = CalnetCrosswalk::ByUid.new(user_id: @uid).lookup_campus_solutions_id
        student = students.detect { |s| campus_solutions_id == s[:campusSolutionsId] }
        student && student[:privileges] && student[:privileges][:viewGrades]
      else
        false
      end
    end
  end
end
