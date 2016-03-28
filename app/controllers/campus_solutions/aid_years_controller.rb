module CampusSolutions
  class AidYearsController < CampusSolutionsController
    include AllowDelegateViewAs

    before_filter :authorize_for_financial

    def get
      render json: CampusSolutions::MyAidYears.from_session(session).get_feed_as_json
    end

  end
end
