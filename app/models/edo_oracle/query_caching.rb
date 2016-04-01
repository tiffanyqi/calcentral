module EdoOracle
  module QueryCaching
    include ClassLogger

    def cached_query(key)
      self.class.fetch_from_cache(key) { yield }
    rescue => e
      logger.error "Query failed for key #{key}: #{e.class}: #{e.message}\n #{e.backtrace.join("\n ")}"
      {}
    end

  end
end
