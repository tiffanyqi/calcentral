module CampusSolutions
  class MyWorkExperience < UserSpecificModel

    include WorkExperienceUpdatingModel

    def update(params = {})
      params[:startDt] = cs_date_formatter params[:startDt]
      params[:endDt] = cs_date_formatter params[:endDt]
      passthrough(CampusSolutions::WorkExperience, params)
    end

    def delete(params = {})
      passthrough(CampusSolutions::WorkExperienceDelete, params)
    end

    # Formats input date to Campus Solutions acceptable ISO 8601 (YYYY-MM-DD)
    # Front-end date validator ensures date will be in '%m/%d/%Y' format
    def cs_date_formatter(date)
      begin
        return Date.strptime(date, '%m/%d/%Y').strftime('%F')
      rescue ArgumentError
        return date
      end
    end

  end
end
