module DisallowAdvisorViewAs
  # Indicates that controller endpoints are unavailable to advisors.
  def allow_if_advisor_view_as?
    false
  end

end
