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
    unless student_or_applicant? student_uid
      raise Pundit::NotAuthorizedError.new "#{student_uid} does not appear to be a current, recent, or incoming student."
    end
  end

  def require_advisor(uid)
    user_attributes = User::AggregatedAttributes.new(uid).get_feed
    authorized = user_attributes && user_attributes[:roles] && user_attributes[:roles][:advisor]
    raise Pundit::NotAuthorizedError.new("User #{uid} is not an Advisor") unless authorized
  end

  private

  def student_or_applicant?(uid)
    @attributes = User::AggregatedAttributes.new(student_uid = uid).get_feed
    @attributes[:roles][:student] || @attributes[:roles][:applicant]
  end

end
