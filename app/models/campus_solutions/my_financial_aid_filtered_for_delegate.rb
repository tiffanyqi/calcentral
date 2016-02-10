module CampusSolutions
  class MyFinancialAidFilteredForDelegate < MyFinancialAidFilteredForAdvisor

    def apply_filter(feed)
      delegate_uid = authentication_state.original_delegate_user_id
      raise RuntimeError, "Only delegate users have access to this filtered #{instance_key} FinAid feed" unless delegate_uid
      logger.debug "Delegate user #{delegate_uid} viewing user #{@uid} financial aid feed where aid_year = #{aid_year}"
      {
        filteredForDelegate: true
      }.merge(remove_family_information feed)
    end

  end
end
