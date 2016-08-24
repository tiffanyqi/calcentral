module HubEdos
  class MyDemographics < UserSpecificModel

    include ClassLogger
    include Cache::CachedFeed
    include Cache::UserCacheExpiry

    def get_feed_internal
      HubEdos::Demographics.new(@options.merge(user_id: @uid)).get
    end

  end
end
