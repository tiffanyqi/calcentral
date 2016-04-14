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
    unless qualifies_as_student? student_uid
      raise Pundit::NotAuthorizedError.new "#{student_uid} does not appear to be a current, recent, or incoming student."
    end
  end

  def require_advisor(uid)
    authorized = (roles = user_roles uid) && roles[:advisor]
    raise Pundit::NotAuthorizedError.new("User #{uid} is not an Advisor") unless authorized
  end

  private

  def qualifies_as_student?(uid)
    (roles = user_roles uid) && (roles[:applicant] || roles[:student] || roles[:recentStudent])
  end

  def user_roles(uid)
    User::AggregatedAttributes.new(uid).get_feed[:roles]
  end

end
