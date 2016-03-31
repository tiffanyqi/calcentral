module DisallowClassicViewAs
  # Indicates that controller endpoints are unavailable to classic View-As for service support staff.
  def allow_if_classic_view_as?
    false
  end
end
