module HubEdos
  class WorkExperience < Student

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/work-experiences"
    end

    def json_filename
      'hub_work_experience.json'
    end

    def include_fields
      %w(workExperiences)
    end

    def build_feed(response)
      student = super(response)['student']
      if student['workExperiences'].present?
        {
          'workExperiences' => student['workExperiences']['workExperiences']
        }
      else
        {}
      end
    end

    def request_options
      super.merge({on_error: {rescue_status: 404}})
    end

  end
end
