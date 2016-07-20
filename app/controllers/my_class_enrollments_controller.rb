class MyClassEnrollmentsController < ApplicationController
  include AllowDelegateViewAs
  before_filter :api_authenticate_401
  before_filter :authorize_for_enrollments

  def get_feed
    render json: MyAcademics::ClassEnrollments.from_session(session).get_feed_as_json
  end
end
