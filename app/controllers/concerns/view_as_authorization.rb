module ViewAsAuthorization
  include AdvisorAuthorization

  def render_403(error)
    if error.respond_to? :message
      render json: { :error => error.message }.to_json, :status => 403
    else
      render :nothing => true, :status => 403
    end
  end

  def authorize_query_stored_users(current_user)
    return if can_view_as_for_all_uids? current_user
    require_advisor current_user.user_id
  end

  private

  def can_view_as_for_all_uids?(user)
    raise Pundit::NotAuthorizedError.new('User information was not found in session.') unless user && user.policy
    user.policy.can_view_as_for_all_uids?
  end

end
