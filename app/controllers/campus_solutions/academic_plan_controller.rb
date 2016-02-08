module CampusSolutions
  class AcademicPlanController < CampusSolutionsController

    def get
      model = CampusSolutions::MyAcademicPlan.from_session(session)
      model.term_id = params['term_id']
      render json: model.get_feed_as_json
    end

  end
end
