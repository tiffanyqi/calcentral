module CampusSolutions
  class MyEmergencyPhone < UserSpecificModel

    include PersonDataUpdatingModel

    def update(params = {})
      passthrough(CampusSolutions::EmergencyPhone, params)
    end

    def delete(params = {})
      passthrough(CampusSolutions::EmergencyPhoneDelete, params)
    end

  end
end
