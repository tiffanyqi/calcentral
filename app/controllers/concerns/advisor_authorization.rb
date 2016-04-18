module AdvisorAuthorization

  def render_403(error)
    if error.respond_to? :message
      render json: { :error => error.message }.to_json, :status => 403
    else
      render :nothing => true, :status => 403
    end
  end

  def authorize_advisor_view_as(uid, student_uid)
    require_advisor uid
    student = user_attributes student_uid
    authorized = (roles = student[:roles]) && (roles[:applicant] || roles[:student] || roles[:recentStudent])
    unless authorized
      message_prefix = "User with UID #{student_uid}"
      message_prefix.concat " / SID #{student[:studentId]}" if student[:studentId]
      raise Pundit::NotAuthorizedError.new "#{message_prefix} does not appear to be a current, recent, or incoming student."
    end
  end

  def require_advisor(uid)
    authorized = (user = user_attributes uid) && user[:roles] && user[:roles][:advisor]
    raise Pundit::NotAuthorizedError.new("User (UID: #{uid}) is not an Advisor") unless authorized
  end

  private

  def user_attributes(uid)
    User::AggregatedAttributes.new(uid).get_feed
  end

end
