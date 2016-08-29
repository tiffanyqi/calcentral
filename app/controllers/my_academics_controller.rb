class MyAcademicsController < ApplicationController
  include AllowDelegateViewAs
  before_filter :api_authenticate
  before_filter :authorize_for_enrollments

  def get_feed
    if current_user.authenticated_as_delegate?
      render json: MyAcademics::FilteredForDelegate.from_session(session).get_feed_as_json
    else
      render json: MyAcademics::Merged.from_session(session).get_feed_as_json
    end
  end

  def residency
    # Delegates get an empty feed.
    return {} if current_user.authenticated_as_delegate?
    render json: MyAcademics::Residency.from_session(session).get_feed_as_json
  end

end
