class MyCal1cardController < ApplicationController
  include DelegateAccessible

  before_filter :api_authenticate
  before_filter :authorize_for_financial

  def get_feed
    render json: Cal1card::MyCal1card.from_session(session).get_feed_as_json
  end

end
