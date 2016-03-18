module CampusSolutions
  class GlobalCachedProxy < Proxy

    def get
      return {} unless is_feature_enabled
      response = self.class.smart_fetch_from_cache(id: instance_key) do
        response = get_internal
        # In at least one case, a working CS ID is needed to call an API which provides a global, non-user-specific
        # value. An invalid ID-less call should not block provision of a properly valued cache by a later user.
        if response && response[:noStudentId]
          raise Errors::ProxyError, "[#{self.class.name}] Cannot call Campus Solutions API without a campus_solutions_id"
        end
        response
      end
      if response.is_a? Hash
        decorate_internal_response response
      else
        {}
      end
    end

    def instance_key
      nil
    end

  end
end
