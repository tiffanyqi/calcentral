module CampusSolutions
  class CollegeSchedulerController < CampusSolutionsController

    # GET /college_scheduler/:acad_career/:term_id
    def get
      proxy = CampusSolutions::CollegeSchedulerUrl.new(user_id: session['user_id'], term_id: params['term_id'], acad_career: params['acad_career'])
      if (college_scheduler_url = proxy.get_college_scheduler_url)
        redirect_to college_scheduler_url
      else
        redirect_to url_for_path '/404'
      end
    end

  end
end
