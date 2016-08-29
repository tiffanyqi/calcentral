module MyAcademics
  class TransitionTerm
    include AcademicsModule
    include User::Student
    include ClassLogger

    # TODO This class collapses two different feeds based on two different data sources and used in two different APIs. Fix!

    # This is included in the MyAcademics::Merged feed, with transition-term based on what's in
    # MyAcademics::CollegeAndLevel, and used to decide the currency of My Academics / Profile.
    def merge(data)
      college_and_level = data[:collegeAndLevel]
      if college_and_level && !college_and_level[:empty] && !college_and_level[:noStudentId]
        data[:transitionTerm] = transition_term college_and_level
      end
    end

    def profile_bucket(college_and_level)
      if (profile_term = Berkeley::TermCodes.from_english college_and_level[:termName])
        time_bucket(profile_term[:term_yr], profile_term[:term_cd])
      end
    end

    # This is called directly from MyBadges::StudentInfo, with transition-term currently
    # determined by whether CalCentral's "current" term differs from the BearFacts "current" term.
    # It is displayed in My Academics / Status, Holds, and Blocks and in the Status popover.
    def regstatus_feed
      # TODO LEGACY ONLY! Must be replaced before Settings.terms.legacy_cutoff.
      if legacy_student?
        response = Regstatus::Proxy.new(user_id: @uid).get
        if response && response[:feed] && (reg_status = response[:feed]['regStatus'])
          {
            registered: reg_status['isRegistered'],
            termName: "#{reg_status['termName']} #{reg_status['termYear']}"
          }
        end
      else
        {}
      end
    end

    def transition_term(college_and_level)
      bucket = profile_bucket college_and_level
      return nil if bucket == 'current'
      # TODO Replace by a flag within the CollegeAndLevel data structure.
      if feed = regstatus_feed
        feed.merge(isProfileCurrent: (bucket != 'past'))
      end
    end
  end
end
