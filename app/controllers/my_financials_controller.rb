class MyFinancialsController < ApplicationController
  include AllowDelegateViewAs
  before_filter :api_authenticate
  before_filter :authorize_for_financial

  def get_feed
    render json: Financials::MyFinancials.from_session(session).get_feed
  end

end
