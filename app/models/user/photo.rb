module User
  class Photo
    extend Cache::Cacheable

    def self.fetch(uid, opts={})
      # Delegate user is not allowed to see his/her student's photo due to privacy concern.
      return nil if opts[SessionKey.original_delegate_user_id]
      cache_key = Cache::KeyGenerator.per_view_as_type uid, opts
      smart_fetch_from_cache({id: cache_key, user_message_on_exception: 'Photo server unreachable'}) do
        CampusOracle::Queries.get_photo(uid)
      end
    end

  end
end
