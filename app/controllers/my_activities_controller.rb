class MyActivitiesController < ApplicationController
  include DelegateAccessible
  before_filter :api_authenticate
  before_filter :authorize_for_financial

  def get_feed
    render :json => MyActivities::Merged.from_session(session).get_feed_as_json
  end
end
