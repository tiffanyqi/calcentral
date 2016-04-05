module AdvisorAuthorization

  def authorize_advisor_view_as(uid, student_uid)
    require_advisor uid
    qualified = student_or_applicant? student_uid
    raise Pundit::NotAuthorizedError.new "#{uid} cannot view #{student_uid} because #{student_uid} does not qualify as a student" unless qualified
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
