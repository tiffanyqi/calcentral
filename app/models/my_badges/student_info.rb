module MyBadges
  class StudentInfo
    include MyBadges::BadgesModule, DatedFeed
    include Cache::UserCacheExpiry

    def initialize(uid)
      @uid = uid
    end

    def get
      # TODO THIS IS CURRENTLY COMPLETELY DEPENDENT ON LEGACY SYSTEMS AND WILL BREAK FOR ALL STUDENTS AS OF FALL 2016
      campus_attributes = CampusOracle::UserAttributes.new(user_id: @uid).get_feed
      result = {
        isLawStudent: law_student?,
        regBlock: get_reg_blocks
      }
      if campus_attributes[:reg_status] && campus_attributes[:reg_status][:transitionTerm]
        result[:regStatus] = get_transition_reg_status(campus_attributes[:reg_status][:code])
      else
        result[:regStatus] = campus_attributes[:reg_status]
      end
      result
    end

    def get_transition_reg_status(code)
      regstatus_feed = MyAcademics::TransitionTerm.new(@uid).regstatus_feed
      return {errored: true} unless regstatus_feed

      if regstatus_feed[:registered]
        Notifications::RegStatusTranslator.new.translate_for_feed 'R'
      elsif code.nil?
        # If not registered during a term transition, let nil status remain nil.
        Notifications::RegStatusTranslator.new.translate_for_feed nil
      else
        # If status is not nil, communicate 'not registered' without alarm.
        {
          code: ' ',
          summary: "Not registered for #{regstatus_feed[:termName]}",
          explanation: nil,
          needsAction: false
        }
      end
    end

    # True if user has a Law 'career' according to Campus Solutions, or if the first college is the School of Law.
    def law_student?
      if (college_feed = MyAcademics::CollegeAndLevel.new(@uid).merge({}))
        if college_feed[:careers].present? && college_feed[:careers].include?('Law')
          true
        else
          college_feed[:majors].present? &&
            college_feed[:majors].first[:college] == Berkeley::Departments.get('CLLAW')
        end
      else
        false
      end
    end

    # "Holds" (the replacement for "Blocks" in the new SIS) are obtained by front-end code directly from a
    # Campus Solutions API.
    def get_reg_blocks
      blocks_feed = Bearfacts::Regblocks.new({user_id: @uid}).get
      response = blocks_feed.slice(:empty, :errored, :noStudentId).merge({
        needsAction: blocks_feed[:activeBlocks].present?,
        activeBlocks: blocks_feed[:activeBlocks].present? ? blocks_feed[:activeBlocks].length : 0
      })
      response
    end
  end

end
