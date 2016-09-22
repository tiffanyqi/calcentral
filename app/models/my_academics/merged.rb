module MyAcademics
  class Merged < UserSpecificModel

    include Cache::LiveUpdatesEnabled
    include Cache::FreshenOnWarm
    include Cache::JsonAddedCacher
    include Cache::FilterJsonOutput
    include MergedModel

    def self.providers
      # Provider ordering is significant! Semesters/Teaching must be merged before course sites.
      # CollegeAndLevel must be merged before TransitionTerm.
      [
        CollegeAndLevel,
        TransitionTerm,
        GpaUnits,
        Requirements,
        Semesters,
        Teaching,
        Exams,
        CanvasSites
      ]
    end

    def get_feed_internal
      feed = {}
      handling_provider_exceptions(feed, self.class.providers) do |provider|
        provider.new(@uid).merge feed
      end
      feed
    end

    def filter_for_view_as(feed)
      if authentication_state.authenticated_as_advisor?
        feed.delete :teachingSemesters
        filter_course_sites feed
      else
        feed
      end
    end

    def filter_course_sites(feed)
      # Course sites can appear in three different parts of the Academics feed:
      #  - semesters/classes/class_sites
      #  - teachingSemesters/classes/class_sites
      #  - otherSiteMemberships/sites
      [:semesters, :teachingSemesters].each do |semesters_key|
        if feed[semesters_key].present?
          feed[semesters_key].each do |term|
            if term[:classes].present?
              term[:classes].each do |course|
                course.delete :class_sites
              end
            end
          end
        end
      end
      feed.delete :otherSiteMemberships
      feed
    end

  end
end
