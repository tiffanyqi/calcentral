module CampusSolutions
  class AdvisingResourcesController < CampusSolutionsController

    def get
      authorize(current_user, :can_view_as_for_all_uids?)
      json_passthrough CampusSolutions::AdvisingResources, user_id: session['user_id'], student_uid: params['student_uid']
    end

  end
end
