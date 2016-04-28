module CampusSolutions
  class BillingController < CampusSolutionsController
    include AllowDelegateViewAs

    before_filter :authorize_for_financial

    def get
      render json: CampusSolutions::MyBilling.from_session(session).get_feed_as_json
    end

  end
end
