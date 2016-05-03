class MyEftEnrollmentController < ApplicationController

  def get_feed
    render json: Eft::MyEftEnrollment.from_session(session).get_feed_as_json
  end

end
