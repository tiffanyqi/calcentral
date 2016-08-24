module CampusSolutions
  module UserApiExpiry
    def self.expire(uid=nil)
      HubEdos::MyStudent.expire uid
      HubEdos::MyAffiliations.expire uid
      HubEdos::MyContacts.expire uid
      HubEdos::MyDemographics.expire uid
      User::Api.expire uid
    end
  end
end
