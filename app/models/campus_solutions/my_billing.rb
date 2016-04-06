module CampusSolutions
  class MyBilling < UserSpecificModel

    include Cache::CachedFeed
    include Cache::JsonifiedFeed
    include Cache::UserCacheExpiry
    include CampusSolutions::BillingFeatureFlagged

    def get_feed_internal
      return {} unless is_feature_enabled
      CampusSolutions::Billing.new({user_id: @uid}).get
    end

  end
end
