module CalnetLdap
  class UserAttributes < BaseProxy
    extend User::Parser

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
        self.class.parse result
      else
        {}
      end
    end

    def self.get_bulk_attributes(uids)
      CalnetLdap::Client.new.search_by_uids(uids).map do |result|
        feed = parse result
        write_cache(feed, feed[:ldap_uid])
        feed
      end
    end

    def self.get_attributes_by_name(name, include_guest_users=false)
      CalnetLdap::Client.new.search_by_name(name, include_guest_users).map do |result|
        feed = parse result
        write_cache(feed, feed[:ldap_uid])
        feed
      end
    end

  end
end
