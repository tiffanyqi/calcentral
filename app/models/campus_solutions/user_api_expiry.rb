module CampusSolutions
  module UserApiExpiry
    def self.expire(uid=nil)
      HubEdos::MyStudent.expire uid
      HubEdos::Affiliations.expire uid
      User::Api.expire uid
    end
  end
end
