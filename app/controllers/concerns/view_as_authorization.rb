module ViewAsAuthorization
  include AdvisorAuthorization

  def authorize_user_lookup(current_user, lookup_uid)
    return if can_view_as_for_all_uids? current_user
    authorize_advisor_view_as current_user.real_user_id, lookup_uid
  end

  def authorize_query_stored_users(current_user)
    return if can_view_as_for_all_uids? current_user
    require_advisor current_user.real_user_id
  end

  private

  def can_view_as_for_all_uids?(user)
    raise Pundit::NotAuthorizedError.new('User information was not found in session.') unless user && user.policy
    user.policy.can_view_as_for_all_uids?
  end

end
