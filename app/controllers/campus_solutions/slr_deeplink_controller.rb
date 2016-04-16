module CampusSolutions
  class SLRDeeplinkController < CampusSolutionsController

    def get
      json_passthrough CampusSolutions::SLRDeeplink, user_id: session['user_id']
    end

  end
end
