module MyGroups
  class Merged < UserSpecificModel

    include Cache::LiveUpdatesEnabled
    include Cache::FreshenOnWarm
    include Cache::JsonAddedCacher
    include Cache::FilterJsonOutput
    include MergedModel

    def self.providers
      [
        MyGroups::Callink,
        MyGroups::Canvas
      ]
    end

    def get_feed_internal
      feed = {
        groups: []
      }
      handling_provider_exceptions(feed, self.class.providers) do |provider|
        feed[:groups].concat provider.new(@uid).fetch
      end
      feed[:groups].sort! { |x, y| x[:name].casecmp y[:name] }
      feed
    end

    def filter_for_view_as(feed)
      if authentication_state.authenticated_as_advisor?
        feed[:groups].delete_if {|t| t[:emitter] == 'bCourses'}
      end
      feed
    end

  end
end
