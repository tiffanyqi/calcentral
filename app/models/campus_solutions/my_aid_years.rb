module CampusSolutions
  class MyAidYears < UserSpecificModel

    include Cache::CachedFeed
    include Cache::JsonAddedCacher
    include Cache::UserCacheExpiry
    include CampusSolutions::FinaidFeatureFlagged

    def get_feed_internal
      return {} unless is_feature_enabled
      CampusSolutions::AidYears.new({user_id: @uid}).get
    end

    def default_aid_year
      feed = self.get_feed
      years = feed && feed[:feed] && feed[:feed][:finaidSummary] && feed[:feed][:finaidSummary][:finaidYears]
      if years && (default_year = years.find { |y| y[:default] })
        default_year[:id]
      end
    end

  end
end
