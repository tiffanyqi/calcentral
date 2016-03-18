module CampusSolutions
  module AcademicProfileFeatureFlagged
    def is_feature_enabled
      Settings.features.cs_academic_profile
    end
  end
end
