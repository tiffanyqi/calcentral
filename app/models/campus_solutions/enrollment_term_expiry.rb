module CampusSolutions
  module EnrollmentTermExpiry
    def self.expire(uid=nil)
      [
        EdoOracle::UserCourses::All,
        MyAcademics::Merged,
        MyAcademics::ClassEnrollments,
        MyAcademics::Registrations
      ].each do |klass|
        klass.expire uid
      end
    end
  end
end
