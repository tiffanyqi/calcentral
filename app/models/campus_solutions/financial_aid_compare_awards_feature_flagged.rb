module CampusSolutions
  module FinancialAidCompareAwardsFeatureFlagged
    def is_feature_enabled
      Settings.features.cs_fin_aid_award_compare
    end
  end
end
