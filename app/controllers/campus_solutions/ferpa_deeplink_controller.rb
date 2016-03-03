module CampusSolutions
  class FerpaDeeplinkController < CampusSolutionsController

    def get
      json_passthrough CampusSolutions::FerpaDeeplink, user_id: session['user_id']
    end

  end
end
