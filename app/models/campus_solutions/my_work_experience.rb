module CampusSolutions
  class MyWorkExperience < UserSpecificModel

    include ClassLogger
    include WorkExperienceUpdatingModel

    def update(params = {})
      params[:startDt] = cs_date_formatter params[:startDt]
      params[:endDt] = cs_date_formatter params[:endDt]
      if !params[:startDt] || !params[:endDt]
        return err_msg
      end
      passthrough(CampusSolutions::WorkExperience, params)
    end

    def delete(params = {})
      passthrough(CampusSolutions::WorkExperienceDelete, params)
    end

    def cs_date_formatter(date)
      begin
        return '' if date.blank?
        Date.strptime(date, '%m/%d/%Y').strftime('%F')
      rescue ArgumentError
        logger.error "Could not parse date string #{date}"
        false
      end
    end

    def err_msg
      {
        statusCode: 400,
        errored: true,
        feed: {
          errmsgtext: "Invalid date format."
        }
      }
    end

  end
end
