module CampusSolutions
  class ResidencyMessageController < CampusSolutionsController

    def get
      json_passthrough(CampusSolutions::ResidencyMessage, {messageNbr: params['messageNbr']})
    end

  end
end
