module MyRegistrations
  class MyRegistrations < UserSpecificModel

    include Cache::CachedFeed
    include Cache::JsonAddedCacher
    include Cache::UserCacheExpiry

    def get_feed_internal
      registrations = get_registrations
      terms = get_terms
      {
        :affiliations => registrations["affiliations"],
        :registrations => match_terms(registrations["registrations"], terms)
      }
    end

    def get_registrations
      registrations = HubEdos::Registrations.new(user_id: @uid).get
      registrations[:feed]
    end

    def get_terms
      berkeleyTerms = Berkeley::Terms.fetch
      {
        :current => berkeleyTerms.current ? berkeleyTerms.current.campus_solutions_id : nil,
        :running => berkeleyTerms.running ? berkeleyTerms.running.campus_solutions_id : nil,
        :sis_current_term => berkeleyTerms.sis_current_term ? berkeleyTerms.sis_current_term.campus_solutions_id : nil,
        :next => berkeleyTerms.next ? berkeleyTerms.next.campus_solutions_id : nil,
        :future => berkeleyTerms.future ? berkeleyTerms.future.campus_solutions_id : nil,
        :previous => berkeleyTerms.previous ? berkeleyTerms.previous.campus_solutions_id : nil,
        :grading_in_progress => berkeleyTerms.grading_in_progress ? berkeleyTerms.grading_in_progress.campus_solutions_id : nil
      }
    end

    private

    # Match registration terms with Berkeley::Terms-defined terms.
    def match_terms(registrations, terms)
      matchedTerms = {}
      terms.each do |key, value|
        # Array format due to the possibility of a single term containing multiple academic career registrations
        matchedTerms[key] = []
        registrations.each do |registration|
          if (value == registration["term"]["id"])
            matchedTerms[key].push(registration)
          end
        end
      end
      matchedTerms
    end

  end
end
