module CampusSolutions
  module BillingFeatureFlagged
    def is_feature_enabled
      Settings.features.cs_billing
    end
  end
end
