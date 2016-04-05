module CampusSolutions
  class AdvisingResourcesController < CampusSolutionsController
    include AdvisorAuthorization

    before_action :authorize_advisor_access

    def get
      json_passthrough CampusSolutions::AdvisingResources, user_id: session['user_id'], student_uid: params['student_uid']
    end

    private

    def authorize_advisor_access
      require_advisor session['user_id']
    end

  end
end
