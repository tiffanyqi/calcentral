require 'net/ldap'

module CalnetLdap
  class Client

    PEOPLE_DN = 'ou=people,dc=berkeley,dc=edu'
    GUEST_DN = 'ou=guests,dc=berkeley,dc=edu'
    TIMESTAMP_FORMAT = '%Y%m%d%H%M%SZ'

    def initialize
      @ldap = Net::LDAP.new({
        host: Settings.ldap.host,
        port: Settings.ldap.port,
        encryption: { method: :simple_tls },
        auth: {
          method: :simple,
          username: Settings.ldap.application_bind,
          password: Settings.ldap.application_password
        }
      })
    end

    def guests_modified_since(timestamp)
      ldap_timestamp = timestamp.to_time.utc.strftime(TIMESTAMP_FORMAT)
      modified_timestamp_filter = Net::LDAP::Filter.ge('modifytimestamp', ldap_timestamp)
      search(base: GUEST_DN, filter: modified_timestamp_filter)
    end

    def search_by_uid(uid)
      filter = Net::LDAP::Filter.eq('uid', uid.to_s)
      results = search(base: PEOPLE_DN, filter: filter)
      if results.empty?
        results = search(base: GUEST_DN, filter: filter)
      end
      results.first
    end

    private

    def search(args = {})
      ActiveSupport::Notifications.instrument('proxy', {class: self.class, search: args}) do
        @ldap.search args
      end
    end

  end
end
