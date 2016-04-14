module CalnetLdap
  module Parser
    include SafeUtf8Encoding

    def parse(ldap_record)
      affiliation_roles = Berkeley::UserRoles.roles_from_ldap_affiliations ldap_record
      group_roles = Berkeley::UserRoles.roles_from_ldap_groups(ldap_record[:berkeleyeduismemberof], !!affiliation_roles[:exStudent])
      roles = group_roles.merge affiliation_roles
      {
        email_address: string_attribute(ldap_record, :mail),
        first_name: string_attribute(ldap_record, :berkeleyEduFirstName) || string_attribute(ldap_record, :givenname),
        last_name: string_attribute(ldap_record, :berkeleyEduLastName) || string_attribute(ldap_record, :sn),
        ldap_uid: string_attribute(ldap_record, :uid),
        person_name: string_attribute(ldap_record, :displayname),
        roles: roles,
        student_id: string_attribute(ldap_record, :berkeleyedustuid),
        official_bmail_address: string_attribute(ldap_record, :berkeleyeduofficialemail)
      }
    end

    def string_attribute(ldap_record, key)
      if (attribute = ldap_record[key].try(:first).try(:to_s))
        safe_utf8 attribute
      end
    end

  end
end
