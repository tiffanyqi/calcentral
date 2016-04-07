module CalnetLdap
  class UserAttributes < BaseProxy

    include Cache::UserCacheExpiry
    extend SafeUtf8Encoding

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
        self.class.parse_result result
      else
        {}
      end
    end

    def self.get_bulk_attributes(uids)
      if (results = CalnetLdap::Client.new.search_by_uids uids)
        results.map { |result| parse_result result }
      end
    end

    def self.parse_result(result)
      affiliation_roles = Berkeley::UserRoles.roles_from_ldap_affiliations result
      group_roles = Berkeley::UserRoles.roles_from_ldap_groups(result[:berkeleyeduismemberof], !!affiliation_roles[:exStudent])
      roles = group_roles.merge affiliation_roles
      {
        email_address: string_attribute(result, :mail),
        first_name: string_attribute(result, :berkeleyEduFirstName) || string_attribute(result, :givenname),
        last_name: string_attribute(result, :berkeleyEduLastName) || string_attribute(result, :sn),
        ldap_uid: string_attribute(result, :uid),
        person_name: string_attribute(result, :displayname),
        roles: roles,
        student_id: string_attribute(result, :berkeleyedustuid),
        official_bmail_address: string_attribute(result, :berkeleyeduofficialemail)
      }
    end

    def self.string_attribute(result, key)
      if (attribute = result[key].try(:first).try(:to_s))
        safe_utf8 attribute
      end
    end

  end
end
