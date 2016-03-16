module CampusSolutions
  class BillingController < CampusSolutionsController

    def get
      render json: CampusSolutions::MyBilling.from_session(session).get_feed_as_json
    end

  end
end
