module CampusSolutions
  module PersonDataExpiry
    def self.expire(uid=nil)
      HubEdos::MyStudent.expire uid
      HubEdos::MyAffiliations.expire uid
      HubEdos::MyContacts.expire uid
      HubEdos::MyDemographics.expire uid
    end
  end
end
