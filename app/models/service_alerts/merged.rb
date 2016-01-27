module ServiceAlerts
  class Merged
    include Cache::CachedFeed
    include Cache::JsonifiedFeed

    def get_feed_internal
      feed = {}
      feed[:releaseNote] = EtsBlog::ReleaseNotes.new.get_latest
      if (latest_alert = ServiceAlerts::Alert.get_latest)
        feed[:alert] = latest_alert.to_feed
      end
      feed
    end

    def instance_key
      nil
    end

  end
end
