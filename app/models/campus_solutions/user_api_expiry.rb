module CampusSolutions
  module UserApiExpiry
    def self.expire(uid=nil)
      User::Api.expire uid
    end
  end
end
