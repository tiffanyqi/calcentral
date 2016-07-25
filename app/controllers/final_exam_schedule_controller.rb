class FinalExamScheduleController < ApplicationController

  before_filter :api_authenticate

  def get_feed
    render :json => Berkeley::FinalExamSchedule.get_feed.to_json
  end

end
