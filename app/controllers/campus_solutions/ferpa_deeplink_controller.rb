module CampusSolutions
  class FerpaDeeplinkController < CampusSolutionsController

    def get
      render json: CampusSolutions::MyFerpaDeeplink.from_session(session).get_feed_as_json
    end

  end
end
