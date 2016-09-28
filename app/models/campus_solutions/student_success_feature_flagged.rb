module CampusSolutions
  module StudentSuccessFeatureFlagged
    def is_feature_enabled
      Settings.features.advising_student_success
    end
  end
end
