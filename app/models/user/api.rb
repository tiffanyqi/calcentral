module User
  class Api < UserSpecificModel
    include ActiveRecordHelper
    include Cache::LiveUpdatesEnabled
    include Cache::FreshenOnWarm
    include Cache::JsonAddedCacher
    include CampusSolutions::ProfileFeatureFlagged
    include CampusSolutions::DelegatedAccessFeatureFlagged
    include ClassLogger

    def init
      use_pooled_connection {
        @calcentral_user_data ||= User::Data.where(:uid => @uid).first
      }
      @oracle_attributes ||= CampusOracle::UserAttributes.new(user_id: @uid).get_feed
      if is_cs_profile_feature_enabled
        @edo_attributes ||= HubEdos::UserAttributes.new(user_id: @uid).get
      end
      @default_name ||= get_campus_attribute('person_name', :string)
      @first_login_at ||= @calcentral_user_data ? @calcentral_user_data.first_login_at : nil
      @first_name ||= get_campus_attribute('first_name', :string) || ''
      @last_name ||= get_campus_attribute('last_name', :string) || ''
      @override_name ||= @calcentral_user_data ? @calcentral_user_data.preferred_name : nil
      @given_first_name = (@edo_attributes && @edo_attributes[:given_name]) || @first_name || ''
      @family_name = (@edo_attributes && @edo_attributes[:family_name]) || @last_name || ''
      @student_id = get_campus_attribute('student_id', :numeric_string)
      @delegate_students = get_delegate_students
    end

    def get_delegate_students
      return nil unless is_cs_delegated_access_feature_enabled
      response = CampusSolutions::DelegateStudents.new(user_id: @uid).get
      response && response[:feed] && response[:feed][:students]
    end

    # split brain until SIS GoLive5 makes registration data available
    def get_campus_attribute(field, format)
      if is_sis_profile_visible? && @edo_attributes[:noStudentId].blank? && (edo_attribute = @edo_attributes[field.to_sym])
        begin
          validated_edo_attribute = validate_attribute(edo_attribute, format)
        rescue
          logger.error "EDO attribute #{field} failed validation for UID #{@uid}: expected a #{format}, got #{edo_attribute}"
        end
      end
      validated_edo_attribute || @oracle_attributes[field]
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

    # Conservative merge of roles from EDO
    WHITELISTED_EDO_ROLES = [:student, :applicant, :advisor]

    def get_campus_roles
      oracle_roles = (@oracle_attributes && @oracle_attributes[:roles]) || {}
      edo_roles = (@edo_attributes && @edo_attributes[:roles]) || {}
      if is_sis_profile_visible? && edo_roles.respond_to?(:slice)
        edo_roles_to_merge = edo_roles.slice *WHITELISTED_EDO_ROLES
        # While we're in the split-brain stage, Oracle views remain our most trusted source on ex-student status.
        edo_roles_to_merge.delete(:student) if oracle_roles[:exStudent]
        oracle_roles.merge edo_roles_to_merge
      else
        oracle_roles
      end
    end

    def preferred_name
      @override_name || @default_name || ''
    end

    def preferred_name=(val)
      if val.blank?
        val = nil
      else
        val.strip!
      end
      @override_name = val
    end

    def self.delete(uid)
      logger.warn "Removing all stored user data for user #{uid}"
      user = nil
      use_pooled_connection {
        Calendar::User.delete_all({uid: uid})
        user = User::Data.where(:uid => uid).first
        if !user.blank?
          user.delete
        end
      }
      if !user.blank?
        GoogleApps::Revoke.new(user_id: uid).revoke
        use_pooled_connection {
          User::Oauth2Data.destroy_all(:uid => uid)
          Notifications::Notification.destroy_all(:uid => uid)
        }
      end

      Cache::UserCacheExpiry.notify uid
    end

    def save
      use_pooled_connection {
        Retriable.retriable(:on => ActiveRecord::RecordNotUnique, :tries => 5) do
          @calcentral_user_data = User::Data.where(uid: @uid).first_or_create do |record|
            logger.debug "Recording first login for #{@uid}"
            record.preferred_name = @override_name
            record.first_login_at = @first_login_at
          end
          if @calcentral_user_data.preferred_name != @override_name
            @calcentral_user_data.update_attribute(:preferred_name, @override_name)
          end
        end
      }
      Cache::UserCacheExpiry.notify @uid
    end

    def update_attributes(attributes)
      init
      if attributes.has_key?(:preferred_name)
        self.preferred_name = attributes[:preferred_name]
      end
      save
    end

    def record_first_login
      init
      @first_login_at = DateTime.now
      save
    end

    def is_campus_solutions_student?
      # no, really, BCS users are identified by having 10-digit IDs.
      @edo_attributes.present? && @edo_attributes[:campus_solutions_id].present? && @edo_attributes[:campus_solutions_id].to_s.length >= 10
    end

    def is_delegate_user?
      authentication_state.directly_authenticated? && !@delegate_students.nil? && @delegate_students.any?
    end

    def is_sis_profile_visible?
      is_cs_profile_feature_enabled &&
        !authentication_state.original_delegate_user_id &&
        (is_campus_solutions_student? || is_profile_visible_for_legacy_users)
    end

    def has_academics_tab?(roles, has_instructor_history, has_student_history, view_as_privileges)
      return false if view_as_privileges && !view_as_privileges[:viewEnrollments] && !view_as_privileges[:viewGrades]
      roles[:student] || roles[:faculty] || has_instructor_history || has_student_history
    end

    def has_financials_tab?(roles, view_as_privileges)
      return false if view_as_privileges && !view_as_privileges[:financial]
      roles[:student] || roles[:exStudent]
    end

    def has_toolbox_tab?(policy, roles)
      return false unless authentication_state.directly_authenticated? && authentication_state.user_auth.active?
      policy.can_administrate? || authentication_state.real_user_auth.is_viewer? || is_delegate_user? || !!roles[:advisor]
    end

    def get_delegate_view_as_privileges
      # The following is not nil when delegate is in view-as session
      delegate_user_id = authentication_state.original_delegate_user_id
      return nil unless is_cs_delegated_access_feature_enabled && delegate_user_id
      if @delegate_students
        campus_solutions_id = CalnetCrosswalk::ByUid.new(user_id: @uid).lookup_campus_solutions_id
        student = @delegate_students.detect { |s| campus_solutions_id == s[:campusSolutionsId] }
        student && student[:privileges]
      else
        nil
      end
    end

    def get_feed_internal
      google_mail = User::Oauth2Data.get_google_email @uid
      canvas_mail = User::Oauth2Data.get_canvas_email @uid
      official_bmail_address = get_campus_attribute('official_bmail_address', :string)
      current_user_policy = authentication_state.policy
      is_google_reminder_dismissed = User::Oauth2Data.is_google_reminder_dismissed(@uid)
      is_google_reminder_dismissed = is_google_reminder_dismissed && is_google_reminder_dismissed.present?
      is_calendar_opted_in = Calendar::User.where(:uid => @uid).first.present?
      has_student_history = CampusOracle::UserCourses::HasStudentHistory.new(user_id: @uid).has_student_history?
      has_instructor_history = CampusOracle::UserCourses::HasInstructorHistory.new(user_id: @uid).has_instructor_history?
      delegate_view_as_privileges = get_delegate_view_as_privileges
      roles = get_campus_roles
      feed = {
        isSuperuser: current_user_policy.can_administrate?,
        isViewer: current_user_policy.can_view_as?,
        firstLoginAt: @first_login_at,
        firstName: @first_name,
        lastName: @last_name,
        fullName: @first_name + ' ' + @last_name,
        givenFirstName: @given_first_name,
        givenFullName: @given_first_name + ' ' + @family_name,
        isGoogleReminderDismissed: is_google_reminder_dismissed,
        isCalendarOptedIn: is_calendar_opted_in,
        hasCanvasAccount: Canvas::Proxy.has_account?(@uid),
        hasGoogleAccessToken: GoogleApps::Proxy.access_granted?(@uid),
        hasStudentHistory: has_student_history,
        hasInstructorHistory: has_instructor_history,
        hasDashboardTab: !authentication_state.original_advisor_user_id && !authentication_state.original_delegate_user_id,
        hasAcademicsTab: has_academics_tab?(roles, has_instructor_history, has_student_history, delegate_view_as_privileges),
        hasFinancialsTab: has_financials_tab?(roles, delegate_view_as_privileges),
        hasToolboxTab: has_toolbox_tab?(current_user_policy, roles),
        hasPhoto: User::Photo.has_photo?(@uid),
        inEducationAbroadProgram: @oracle_attributes[:education_abroad],
        googleEmail: google_mail,
        canvasEmail: canvas_mail,
        officialBmailAddress: official_bmail_address,
        preferredName: self.preferred_name,
        roles: roles,
        uid: @uid,
        sid: @student_id,
        campusSolutionsID: get_campus_attribute('campus_solutions_id', :string),
        isCampusSolutionsStudent: is_campus_solutions_student?,
        isDelegateUser: is_delegate_user?,
        showSisProfileUI: is_sis_profile_visible?
      }
      feed[:delegateViewAsPrivileges] = delegate_view_as_privileges if delegate_view_as_privileges
      feed
    end

  end
end
