require 'net/ldap'

module CalnetLdap
  class Client
    include ClassLogger

    PEOPLE_DN = 'ou=people,dc=berkeley,dc=edu'
    GUEST_DN = 'ou=guests,dc=berkeley,dc=edu'
    TIMESTAMP_FORMAT = '%Y%m%d%H%M%SZ'

    # TODO Ask CalNet for suggested maximum number of search values.
    BATCH_QUERY_MAXIMUM = 20

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

    def search_by_name(name, include_guest_users=false)
      results = []
      if (tokens = tokenize_for_search_by_name name).any?
        tokens.permutation.to_a.each do |args|
          search_by = Net::LDAP::Filter.eq 'displayname', "#{args.join '* '}*"
          results.concat search(base: PEOPLE_DN, filter: search_by)
          results.concat search(base: GUEST_DN, filter: search_by) if include_guest_users
        end
      end
      results
    end

    def search_by_uid(uid)
      filter = uids_filter([uid])
      results = search(base: PEOPLE_DN, filter: filter)
      if results.empty?
        results = search(base: GUEST_DN, filter: filter)
      end
      results.first
    end

    def search_by_uids(uids)
      [].tap do |results|
        uids.each_slice(BATCH_QUERY_MAXIMUM).map do |uid_slice|
          people_results = search(base: PEOPLE_DN, filter: uids_filter(uid_slice))
          results.concat people_results
          if people_results.length != uid_slice.length
            remaining_uids = uid_slice - people_results.collect { |entry| entry[:uid].first }
            guest_results = search(base: GUEST_DN, filter: uids_filter(remaining_uids))
            results.concat guest_results
          end
        end
      end
    end

    private

    def uids_filter(uids)
      uids.map { |uid| Net::LDAP::Filter.eq('uid', uid.to_s) }.inject :|
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

    def tokenize_for_search_by_name(phrase)
      return [] if phrase.blank?
      tokens = phrase.strip.downcase.gsub(/[;,\s]+/, ' ').split /[\s,]/
      # Discard middle initials, generational designations (e.g., Jr.) and academic suffixes (e.g., M.A.)
      tokens.select { |token| !token.end_with? '.' }
    end

  end
end
