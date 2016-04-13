module CalnetLdap
  class UserAttributes < BaseProxy

    include Parser
    include Cache::UserCacheExpiry

    def initialize(options = {})
      super(Settings.ldap, options)
    end

    def get_feed
      self.class.fetch_from_cache @uid do
        @fake ? {} : get_feed_internal
      end
    end

    def get_feed_internal
      if (result = CalnetLdap::Client.new.search_by_uid @uid)
        parse result
      else
        {}
      end
    end

    def self.get_bulk_attributes(uids)
      if (results = CalnetLdap::Client.new.search_by_uids uids)
        results.map { |result| parse result }
      end
    end

  end
end
