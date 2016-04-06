module CampusSolutions
  class MyAcademicPlan < UserSpecificModel

    include Cache::CachedFeed
    include Cache::JsonifiedFeed
    include Cache::UserCacheExpiry
    include EnrollmentCardFeatureFlagged

    attr_accessor :term_id

    def get_feed_internal
      return {} unless is_feature_enabled && HubEdos::UserAttributes.new(user_id: @uid).has_role?(:student)
      CampusSolutions::AcademicPlan.new(user_id: @uid, term_id: term_id).get
    end

    def instance_key
      "#{@uid}-#{term_id || 'all'}"
    end

  end
end
