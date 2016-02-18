module CampusSolutions
  class MyFerpaDeeplink < UserSpecificModel

    include Cache::LiveUpdatesEnabled
    include Cache::FreshenOnWarm
    include Cache::JsonAddedCacher

    def get_feed_internal
      CampusSolutions::FerpaDeeplink.new({user_id: @uid}).get
    end

  end
end

