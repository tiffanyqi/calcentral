module HubEdos
  class WorkExperience < Proxy

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/work-experiences"
    end

    def json_filename
      'hub_work_experience.json'
    end

    def build_feed(response)
      resp = parse_response response
      students = get_students(resp)
      if students.any? && students[0]['workExperiences'].present?
        {
          'workExperiences' => students[0]['workExperiences']['workExperiences']
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
