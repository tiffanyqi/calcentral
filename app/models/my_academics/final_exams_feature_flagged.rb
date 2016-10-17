module MyAcademics
  module FinalExamsFeatureFlagged
    def is_feature_enabled
      Settings.features.final_exam_schedule
    end
  end
end
