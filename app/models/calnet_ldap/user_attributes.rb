module CalnetLdap
  class UserAttributes < BaseProxy

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
        if result[:berkeleyeduaffiliations].present?
          roles = Berkeley::UserRoles.roles_from_ldap_affiliations(result)
        end
        {
          email_address: result[:mail].try(:first),
          first_name: result[:givenname].try(:first),
          last_name: result[:sn].try(:first),
          ldap_uid: result[:uid].try(:first).try(:to_s),
          person_name: result[:displayname].try(:first),
          roles: roles,
          student_id: result[:berkeleyedustuid].try(:first).try(:to_s),
          official_bmail_address: result[:berkeleyeduofficialemail].try(:first)
        }
      else
        {}
      end
    end
  end
end
