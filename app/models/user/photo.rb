module User
  class Photo
    extend Cache::Cacheable

    def self.fetch(uid, opts={})
      # Delegate user is not allowed to see his/her student's photo due to privacy concern.
      return nil if opts[SessionKey.original_delegate_user_id]
      cache_key = Cache::KeyGenerator.per_view_as_type uid, opts
      photo_feed = smart_fetch_from_cache({id: cache_key, user_message_on_exception: 'Photo server unreachable'}) do
        Cal1card::Photo.new(uid).get_feed
      end
      photo_feed[:photo] ? photo_feed : nil
    end

  end
end
