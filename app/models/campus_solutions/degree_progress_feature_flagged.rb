module CampusSolutions
  module DegreeProgressFeatureFlagged
    def is_feature_enabled
      Settings.features.cs_degree_progress
    end
  end
end
