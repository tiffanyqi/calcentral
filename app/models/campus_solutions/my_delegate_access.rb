module CampusSolutions
  class MyDelegateAccess < UserSpecificModel

    include DelegatedAccessFeatureFlagged

    def get_feed
      return {} unless is_feature_enabled
      CampusSolutions::DelegateStudents.new(user_id: @uid).get
    end

    def update(params = {})
      feed = CampusSolutions::DelegateAccessCreate.new(user_id: @uid, params: params).get
    rescue => e
      logger.error "#{self.class.name} failed where uid = #{@uid}"
      raise e
    else
      DelegateStudentsExpiry.expire @uid
      feed
    end

  end
end
