module DelegateAccessible
  # Indicates that controller endpoints are either publicly available or filtered for delegated access.
  def accessible_by_delegate?
    true
  end

  def authorize_for_enrollments
    if current_user.authenticated_as_delegate?
      unless current_user.delegated_privileges[:viewEnrollments] || current_user.delegated_privileges[:viewGrades]
        raise Pundit::NotAuthorizedError.new("By delegate #{current_user.original_delegate_user_id}")
      end
    end
  end

  def authorize_for_financial
    if current_user.authenticated_as_delegate?
      unless current_user.delegated_privileges[:financial]
        raise Pundit::NotAuthorizedError.new("By delegate #{current_user.original_delegate_user_id}")
      end
    end
  end

end
