module CampusSolutions
  class DegreeProgressController < CampusSolutionsController

    include AllowDelegateViewAs

    def get
      render json: MyAcademics::DegreeProgress.from_session(session).get_feed_as_json
    end

  end
end
