module CampusSolutions
  module DelegateStudentsExpiry
    def self.expire(uid=nil)
      CampusSolutions::DelegateStudents.expire uid
    end
  end
end
