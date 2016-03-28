class ServiceAlertsController < ApplicationController
  include AllowDelegateViewAs

  def get_feed
    render json: ServiceAlerts::Merged.new.get_feed_as_json
  end

end
