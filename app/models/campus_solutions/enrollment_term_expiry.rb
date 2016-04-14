module CampusSolutions
  module EnrollmentTermExpiry
    def self.expire(uid=nil)
      [
        MyEnrollmentTerm,
        MyEnrollmentTerms,
        EdoOracle::UserCourses::All,
        MyAcademics::Merged
      ].each do |klass|
        klass.expire uid
      end
    end
  end
end
