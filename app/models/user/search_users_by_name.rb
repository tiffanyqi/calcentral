module User
  class SearchUsersByName
    include CalnetLdap::Parser
    extend Cache::Cacheable

    def search_by(name, opts={})
      results = CalnetLdap::Client.new.search_by_name(name, !!opts[:include_guest_users])
      filter_by_roles results, opts[:roles]
    end

    private

    def filter_by_roles(ldap_records, roles)
      return [] if ldap_records.empty?
      users = ldap_records.map { |ldap_record| self.parse ldap_record }
      return users if roles.nil?
      users.select { |user| matching_role? user, roles }
    end

    def matching_role?(user, roles=[])
      !!((user_roles = user[:roles]) && roles.detect { |role| user_roles[role] })
    end

  end
end
