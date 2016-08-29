module Cache
  module CachedFeed
    def self.included(klass)
      klass.extend Cache::Cacheable
    end

    def init
      # override to do any initialization that requires database access or other expensive computation.
      # If you do expensive work from initialize, it will happen even when this object is cached -- not desirable!
      self
    end

    def get_feed(force_cache_write=false)
      response = self.class.fetch_from_cache(instance_key, force_cache_write) do
        init
        get_feed_internal
      end
      process_response_after_caching response
    end

    def get_feed_as_json(force_cache_write=false)
      get_feed(force_cache_write).to_json
    end

    def expire_cache
      self.class.expire(instance_key)
    end

    def extended_instance_keys
      [instance_key]
    end

    # Override for single-instantiation processing of cached data, such as filtering or obfuscating to match
    # current user authorization.
    def process_response_after_caching(response)
      response
    end

  end
end
