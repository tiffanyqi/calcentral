module CampusSolutions
  class MyFinancialAidFilteredForAdvisor < UserSpecificModel

    include ClassLogger
    include Cache::CachedFeed
    include Cache::JsonAddedCacher
    include Cache::RelatedCacheKeyTracker
    include CampusSolutions::FinaidFeatureFlagged

    attr_accessor :aid_year

    def get_feed_as_json(force_cache_write=false)
      feed = get_feed force_cache_write
      feed.to_json
    end

    def get_feed_internal
      if is_feature_enabled && (self.aid_year ||= CampusSolutions::MyAidYears.new(@uid).default_aid_year)
        apply_filter CampusSolutions::FinancialAidData.new(user_id: @uid, aid_year: aid_year).get
      else
        {}
      end
    end

    def apply_filter(feed)
      advisor_uid = authentication_state.original_advisor_user_id
      raise RuntimeError, "Only advisors have access to this filtered #{instance_key} FinAid feed" unless advisor_uid
      logger.debug "Advisor #{advisor_uid} viewing user #{@uid} financial aid feed where aid_year = #{aid_year}"
      {
        filteredForAdvisor: true
      }.merge(remove_family_information feed)
    end

    def remove_family_information(feed={})
      return feed unless feed[:feed] && feed[:feed][:status] && (categories = feed[:feed][:status][:categories])
      categories.each do |category|
        if category[:itemGroups]
          filtered_groups = []
          category[:itemGroups].each do |group|
            exclude_group = group.any? { |item| has_family_information? item }
            filtered_groups << group unless exclude_group
          end
          category[:itemGroups] = filtered_groups
        end
      end
      feed
    end

    def instance_key
      "#{@uid}-#{aid_year}"
    end

    def has_family_information?(item)
      [item[:title].to_s, item[:value].to_s].any? { |s| s =~ /family|efc|parent/i }
    end
  end
end
