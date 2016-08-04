module CampusSolutions
  module AdvisingExpiry
    def self.expire(uid=nil)
      [Advising::MyAdvising, CampusSolutions::AdvisingResources].each do |klass|
        klass.expire uid
      end
    end
  end
end
