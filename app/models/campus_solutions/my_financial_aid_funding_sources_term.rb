module CampusSolutions
  class MyFinancialAidFundingSourcesTerm < UserSpecificModel

    include ClassLogger
    include Cache::LiveUpdatesEnabled
    include Cache::FreshenOnWarm
    include Cache::JsonAddedCacher
    include Cache::RelatedCacheKeyTracker
    include CampusSolutions::FinaidFeatureFlagged

    attr_accessor :aid_year

    def get_feed_internal
      return {} unless is_feature_enabled
      logger.debug "User #{@uid}; aid year #{aid_year}"
      CampusSolutions::FinancialAidFundingSourcesTerm.new({user_id: @uid, aid_year: aid_year}).get
    end

    def instance_key
      "#{@uid}-#{aid_year}"
    end

  end
end
