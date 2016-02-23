module CampusSolutions
  class MyWorkExperience < UserSpecificModel

    include PersonDataUpdatingModel

    def update(params = {})
      passthrough(CampusSolutions::WorkExperience, params)
    end

    def delete(params = {})
      passthrough(CampusSolutions::WorkExperienceDelete, params)
    end

  end
end
