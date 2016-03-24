module User
  class AggregatedAttributes < UserSpecificModel
    include CampusSolutions::ProfileFeatureFlagged
    include Cache::RelatedCacheKeyTracker

    attr_reader :campus_solutions_id, :student_id, :given_first_name, :first_name, :last_name, :family_name, :default_name
    attr_reader :roles, :primary_email_address, :official_bmail_address, :education_abroad, :campus_solutions_student, :sis_profile_visible
    alias_method :education_abroad?, :education_abroad
    alias_method :campus_solutions_student?, :campus_solutions_student
    alias_method :sis_profile_visible?, :sis_profile_visible

    # Conservative merge of roles from EDO
    WHITELISTED_EDO_ROLES = [:student, :applicant, :advisor]

    def initialize(uid, options={})
      super(uid, options)
      @ldap_attributes = CalnetLdap::UserAttributes.new(user_id: @uid).get_feed
      @oracle_attributes = CampusOracle::UserAttributes.new(user_id: @uid).get_feed
      if is_cs_profile_feature_enabled
        @edo_attributes = HubEdos::UserAttributes.new(user_id: @uid).get
      end
      @campus_solutions_student = @edo_attributes.present? && (@edo_attributes[:is_legacy_user] == false)
      @sis_profile_visible = is_cs_profile_feature_enabled && (@campus_solutions_student || is_profile_visible_for_legacy_users)
      @roles = get_campus_roles
      # Names
      @default_name = get_campus_attribute('person_name', :string)
      @first_name = get_campus_attribute('first_name', :string) || ''
      @last_name = get_campus_attribute('last_name', :string) || ''
      @given_first_name = (@edo_attributes && @edo_attributes[:given_name]) || @first_name || ''
      @family_name = (@edo_attributes && @edo_attributes[:family_name]) || @last_name || ''
      # Identifiers
      @student_id = get_campus_attribute('student_id', :numeric_string)
      @campus_solutions_id = get_campus_attribute('campus_solutions_id', :string)
      # Other
      @primary_email_address = get_campus_attribute('email_address', :string)
      @official_bmail_address = get_campus_attribute('official_bmail_address', :string)
      @education_abroad = !!@oracle_attributes[:education_abroad]
    end

    private

    def get_campus_roles
      ldap_roles = (@ldap_attributes && @ldap_attributes[:roles]) || {}
      oracle_roles = (@oracle_attributes && @oracle_attributes[:roles]) || {}
      campus_roles = oracle_roles.merge ldap_roles
      if sis_profile_visible?
        edo_roles = (@edo_attributes && @edo_attributes[:roles]) || {}
        edo_roles_to_merge = edo_roles.slice *WHITELISTED_EDO_ROLES
        # While we're in the split-brain stage, LDAP and Oracle are more trusted on ex-student status.
        edo_roles_to_merge.delete(:student) if campus_roles[:exStudent]
        campus_roles.merge edo_roles_to_merge
      else
        campus_roles
      end
    end

    # Split brain three ways until some subset of the brain proves more trustworthy.
    def get_campus_attribute(field, format)
      if sis_profile_visible? &&
        (@roles[:student] || @roles[:applicant]) &&
        @edo_attributes[:noStudentId].blank? && (edo_attribute = @edo_attributes[field.to_sym])
        begin
          validated_edo_attribute = validate_attribute(edo_attribute, format)
        rescue
          logger.error "EDO attribute #{field} failed validation for UID #{@uid}: expected a #{format}, got #{edo_attribute}"
        end
      end
      validated_edo_attribute || @ldap_attributes[field.to_sym] || @oracle_attributes[field]
    end

    def validate_attribute(value, format)
      case format
        when :string
          raise ArgumentError unless value.is_a?(String) && value.present?
        when :numeric_string
          raise ArgumentError unless value.is_a?(String) && Integer(value, 10)
      end
      value
    end

  end
end
