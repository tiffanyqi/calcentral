module CampusSolutions
  class LinkController < CampusSolutionsController

    def get
      render json: CampusSolutions::Link.new(params).get_url(params['urlId'])
    end

  end
end
