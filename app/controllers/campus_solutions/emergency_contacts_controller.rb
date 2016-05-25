module CampusSolutions
  class EmergencyContactsController < CampusSolutionsController

    def get
      json_passthrough CampusSolutions::EmergencyContacts, user_id: session['user_id']
    end

  end
end
