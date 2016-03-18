module CampusSolutions
  module UserApiExpiry
    def self.expire(uid=nil)
      HubEdos::MyStudent.expire uid
      User::Api.expire uid
    end
  end
end
