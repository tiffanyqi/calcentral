module CampusSolutions
  module StudentLookupFeatureFlagged
    def is_feature_enabled
      Settings.features.cs_advisor_student_lookup
    end
  end
end
