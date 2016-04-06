module User
  class Photo

    def self.fetch(uid, opts={})
      # Delegate user is not allowed to see his/her student's photo due to privacy concern.
      return nil if opts[SessionKey.original_delegate_user_id]
      photo_feed = Cal1card::Photo.new(uid).get_feed
      photo_feed[:photo] ? photo_feed : nil
    end

  end
end
