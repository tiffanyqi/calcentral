class DelegateActAsController < ActAsController

  def initialize
    super(act_as_session_key: 'original_delegate_user_id')
  end

  def act_as_authorization(uid_param)
    acting_user_id = current_user.real_user_id
    # Expire cache prior to view-as session to guarantee most up-to-date privileges.
    CampusSolutions::DelegateStudentsExpiry.expire @uid
    response = CampusSolutions::DelegateStudents.new(user_id: acting_user_id).get
    if response[:feed] && (students = response[:feed][:students])
      student = students.detect { |s| uid_param == s[:uid] }
      authorized = student && [:financial, :viewEnrollments, :viewGrades].any? { |k| student[:privileges][k] }
      raise NotAuthorizedError.new("User #{acting_user_id} is unauthorized to delegate-view-as student: #{student.as_json}") unless authorized
      logger.warn "User #{acting_user_id} is authorized to delegate-view-as #{uid_param} with privileges: #{student[:privileges]}"
    else
      raise NotAuthorizedError.new "User #{acting_user_id} does not have delegate affiliation"
    end
  end

  def after_successful_start(session, params)
    # Do nothing
  end

end
