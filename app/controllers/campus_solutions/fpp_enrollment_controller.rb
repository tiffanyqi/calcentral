module CampusSolutions
  class FppEnrollmentController < CampusSolutionsController

    include DisallowAdvisorViewAs
    include DisallowClassicViewAs

    def get
      json_passthrough CampusSolutions::FppEnrollment
    end

  end
end
