module EdoOracle
  class Connection < OracleBase
    # WARNING: Default Rails SQL query caching (done for the lifetime of a controller action) apparently does not apply
    # to anything but the primary DB connection. Any Oracle query caching needs to be handled explicitly.
    establish_connection :edodb

    def self.settings
      Settings.edodb
    end

    def self.stringified_columns
      %w(section_id campus-uid)
    end

    def self.terms_query_list(terms = nil)
      terms.try :compact!
      return '' unless terms.present?
      terms.map { |term| "'#{term.campus_solutions_id}'" }.join ','
    end
  end
end
