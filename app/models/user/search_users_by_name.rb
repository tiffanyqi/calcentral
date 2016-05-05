module User
  class SearchUsersByName
    include User::Parser

    def search_by(name, opts={})
      return [] if name.blank?
      raise ArgumentError, 'Wildcard-only searches are not allowed.' if only_special_characters?(name)
      # TODO: For now, you must opt-in to search via Campus Solutions; LDAP remains the default.
      opt_in = !!opts[:search_campus_solutions]
      users = opt_in ? search_campus_solutions(name, opts) : search_ldap(name, opts)
      users.each do |user|
        # We negotiate the differences between LDAP and Campus Solutions.
        user[:name] ||= user[:person_name]
        user[:sid] ||= user[:student_id]
        user[:ldapUid] ||= user[:ldap_uid]
      end
      users
    end

    private

    def only_special_characters?(name)
      !!(name =~ /^[\*\?\s]+$/)
    end

    def search_ldap(name, opts)
      ldap_records = CalnetLdap::Client.new.search_by_name(name, !!opts[:include_guest_users])
      users = parse_all(ldap_records)
      filter_by_roles users, opts[:roles]
    end

    def search_campus_solutions(name, opts)
      cs_search_options = search_by_name_options(name, opts)
      return [] if cs_search_options[:name_1].blank?
      results = []
      if (feed = CampusSolutions::UserSearch.new(cs_search_options).get[:feed])
        results.concat feed[:users]
      end
      if (roles = opts[:roles]) && roles.include?(:recentStudent)
        ldap_records = CalnetLdap::Client.new.search_by_name name, !!opts[:include_guest_users]
        results.concat filter_by_roles(parse_all(ldap_records), {recentStudent: true })
      end
      results
    end

    def search_by_name_options(name, opts={})
      # We collect HTTP query args for the upcoming call to Campus Solutions API.
      unless name.blank?
        if name.include? ','
          # Comma implies last-name first. For example: 'Obama Jr., Barack Hussein'
          split = name.split ',', 2
          opts[:name_1] = tokenize_for_search_by_name(split[1]).join ' '
          opts[:name_2] = tokenize_for_search_by_name(split[0]).join ' '
        else
          tokens = tokenize_for_search_by_name name
          case tokens.length
            when 1..2
              # 'Barack' or 'Barack Obama'
              opts[:name_1] = tokens[0]
              opts[:name_2] = tokens[1] if tokens.length > 1
            else
              # Treat second token as middle-name. For example: 'Barack Hussein Obama II'
              opts[:name_1] = "#{tokens[0]} #{tokens[1]}"
              opts[:name_2] = tokens.drop(2).join ' '
          end
        end
      end
      opts[:affiliations] = opts[:roles].map(&:to_s).map(&:upcase) if opts.has_key? :roles
      opts
    end

  end
end
