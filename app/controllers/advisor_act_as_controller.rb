class AdvisorActAsController < ActAsController
  include CampusSolutions::ProfileFeatureFlagged

  skip_before_filter :check_reauthentication, :only => [:stop_advisor_act_as]

  def initialize
    super act_as_session_key: SessionKey.original_advisor_user_id
  end

  def act_as_authorization(uid_param)
    if is_cs_profile_feature_enabled
      user_id = current_user.real_user_id
      user_attributes = HubEdos::UserAttributes.new(user_id: user_id).get
      authorized = user_attributes && user_attributes[:roles] && user_attributes[:roles][:advisor]
      raise Pundit::NotAuthorizedError.new("User #{user_id} is not an Advisor and thus cannot view-as #{uid_param}") unless authorized
    else
      raise Pundit::NotAuthorizedError.new 'We cannot confirm your role as an Advisor because Campus Solutions is unavailable. Please contact us if the problem persists.'
    end
  end
end
