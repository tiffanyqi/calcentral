module HubEdos
  module CachedProxy
    def get(opts = {})
      return {} unless is_feature_enabled
      response = self.class.smart_fetch_from_cache(opts.merge(id: instance_key)) do
        get_internal
      end
      self.class.decorate_internal_response response
    end
  end
end

