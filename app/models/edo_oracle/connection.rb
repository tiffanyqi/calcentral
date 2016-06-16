module EdoOracle
  class Connection < OracleBase

    def self.settings
      Settings.edodb
    end

    def self.safe_query(sql)
      result = []
      return result if fake?
      use_pooled_connection do
        result = connection.select_all sql
      end
      stringify_ints! result
    rescue => e
      logger.error "Query failed: #{e.class}: #{e.message}\n #{e.backtrace.join("\n ")}"
      []
    end

    def self.stringified_columns
      %w(section_id campus-uid)
    end

    def self.terms_query_list(terms = nil)
      terms.try :compact!
      return '' unless terms.present?
      terms.map { |term| "'#{term.campus_solutions_id}'" }.join ','
    end

    # WARNING: Default Rails SQL query caching (done for the lifetime of a controller action) apparently does not apply
    # to anything but the primary DB connection. Any Oracle query caching needs to be handled explicitly.
    establish_connection :edodb unless fake?
  end
end
