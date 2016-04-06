module HubEdos
  class MyWorkExperience < UserSpecificModel

    include ClassLogger
    include Cache::CachedFeed
    include Cache::JsonifiedFeed
    include Cache::UserCacheExpiry
    include CampusSolutions::ProfileFeatureFlagged

    def get_feed_internal
      return {} unless is_cs_profile_feature_enabled
      HubEdos::WorkExperience.new({user_id: @uid}).get
    end

  end
end
