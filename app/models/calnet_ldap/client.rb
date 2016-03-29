require 'net/ldap'

module CalnetLdap
  class Client
    include ClassLogger

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
      filter = uids_filter([uid])
      results = search(base: PEOPLE_DN, filter: filter)
      if results.empty?
        results = search(base: GUEST_DN, filter: filter)
      end
      results.first
    end

    # TODO Ask CalNet for suggested maximum number of search values.
    # For now, it would be safest to limit batches to 20 or less.
    def search_by_uids(uids)
      results = search(base: PEOPLE_DN, filter: uids_filter(uids))
      if results.length != uids.length
        remaining_uids = uids - results.collect {|entry| entry[:uid].first}
        results.concat search(base: GUEST_DN, filter: uids_filter(remaining_uids))
      end
      results
    end

    private

    def uids_filter(uids)
      filters = nil
      uids.each do |uid|
        filters = filters.nil? ? Net::LDAP::Filter.eq('uid', uid.to_s) : filters | Net::LDAP::Filter.eq('uid', uid.to_s)
      end
      filters
    end

    def search(args = {})
      ActiveSupport::Notifications.instrument('proxy', {class: self.class, search: args}) do
        response = @ldap.search args
        if response.nil?
          logger.error "LDAP error returned: #{@ldap.get_operation_result}"
          []
        else
          response
        end
      end
    end

  end
end
