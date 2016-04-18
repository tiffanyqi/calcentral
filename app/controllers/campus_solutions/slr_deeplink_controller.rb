module CampusSolutions
  class SlrDeeplinkController < CampusSolutionsController

    include DisallowAdvisorViewAs
    include DisallowClassicViewAs

    def get
      json_passthrough CampusSolutions::SlrDeeplink
    end

  end
end
