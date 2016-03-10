module Cache
  module RelatedCacheKeyTracker

    # This hook is used for mixins with BaseProxy subclasses.
    def get
      result = super
      self.class.save_related_cache_key(@uid, self.class.cache_key(instance_key))
      result
    end

    # This hook is used for mixins with Cache::CachedFeed.
    def get_feed(force_cache_write=false)
      feed = super force_cache_write
      extended_instance_keys.each do |key|
        self.class.save_related_cache_key(@uid, self.class.cache_key(key))
      end
      feed
    end

    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods
      def user_key(uid)
        cache_key "related-cache-keys-#{uid}"
      end

      def expire(uid=nil)
        # The list of related cache keys should contain ALL germane cache keys for this combination of
        # user and class, and so a call to the superclasss's expire method is unnecessary.
        related_keys = related_cache_keys uid
        logger.debug "Will now expire these associated keys for uid #{uid}: #{related_keys.inspect}"
        related_keys.keys.each do |related_key|
          Rails.cache.delete related_key
        end
        Rails.cache.delete(user_key(uid))
      end

      def related_cache_keys(uid=nil)
        Rails.cache.read(user_key(uid)) || {}
      end

      def save_related_cache_key(uid=nil, related_key=nil)
        related_keys = related_cache_keys uid
        return if related_keys[related_key].present?
        related_keys[related_key] = 1
        logger.debug "Writing related keys for uid #{uid}: #{related_keys.inspect}"
        Rails.cache.write(user_key(uid),
                          related_keys,
                          :expires_in => Settings.cache.maximum_expires_in,
                          :force => true)
      end
    end
  end
end
