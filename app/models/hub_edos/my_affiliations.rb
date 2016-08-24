module HubEdos
  class MyAffiliations < UserSpecificModel

    include ClassLogger
    include Cache::CachedFeed
    include Cache::UserCacheExpiry

    def get_feed_internal
      HubEdos::Affiliations.new(@options.merge(user_id: @uid)).get
    end

  end
end
