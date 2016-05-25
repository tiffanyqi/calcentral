module CampusSolutions
  module EmergencyContactsFeatureFlagged
    def is_feature_enabled
      Settings.features.cs_profile_emergency_contacts
    end
  end
end
