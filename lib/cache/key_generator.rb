module Cache
  module KeyGenerator

    def self.per_view_as_type(default_key, opts={})
      # View-as-UID:12345 cache should not be shared with standard UID:12345 cache thus the distinct keys.
      (SessionKey::VIEW_AS_TYPES + SessionKey::CANVAS_MASQUERADE_TYPES).each do |view_as_type|
        if opts[view_as_type]
          return "#{default_key}/#{view_as_type}:#{opts[view_as_type]}"
        end
      end
      default_key
    end

  end
end
