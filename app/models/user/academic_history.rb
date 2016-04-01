module User
  class AcademicHistory < UserSpecificModel
    def has_instructor_history?(current_terms)
      grouped_terms = Berkeley::Terms.legacy_group(current_terms)
      has_legacy_instructor_history = Proc.new { CampusOracle::Queries.has_instructor_history?(@uid, grouped_terms[:legacy]) }
      has_sisedo_instructor_history = Proc.new { EdoOracle::Queries.has_instructor_history?(@uid, grouped_terms[:sisedo]) }
      return has_legacy_instructor_history.call || has_sisedo_instructor_history.call
    end
  end
end
