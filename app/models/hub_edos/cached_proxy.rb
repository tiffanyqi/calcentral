module HubEdos
  module CachedProxy
    def get(opts = {})
      return {} unless is_feature_enabled
      response = self.class.smart_fetch_from_cache(opts.merge(id: instance_key)) do
        get_internal
      end
      process_response_after_caching response
    end
  end
end
