module MyAcademics
  class DegreeProgress < UserSpecificModel
    include Cache::CachedFeed
    include Cache::JsonifiedFeed
    include Cache::UserCacheExpiry
    include CampusSolutions::DegreeProgressFeatureFlagged

    CAREER_LAW = 'LAW'
    ACAD_PROG_CODE_LACAD = 'LACAD'
    LINKS_CONFIG = [
      { feed_key: :advancement_form_submit, cs_link_key: 'UC_CX_GT_AAQEAPPLIC_ADD' },
      { feed_key: :advancement_form_view, cs_link_key: 'UC_CX_GT_AAQEAPPLIC_VIEW' }
    ]

    def get_feed_internal
      return {} unless is_feature_enabled
      response = CampusSolutions::DegreeProgress.new(user_id: @uid).get
      degree_progress = response.try(:[], :feed).try(:[], :ucAaProgress).try(:[], :progresses)
      response[:feed] = HashConverter.camelize({
        degree_progress: massage_progresses(degree_progress),
        links: get_links
      })
      response
    end

    def get_links
      links = {}
      LINKS_CONFIG.each do |setting|
        link = fetch_link setting[:cs_link_key]
        links[setting[:feed_key]] = link unless link.blank?
      end
      links
    end

    def fetch_link(link_key)
      if (link_feed = CampusSolutions::Link.new.get_url link_key)
        link = link_feed.try(:[], :link)
      end
      logger.error "Could not retrieve CS link #{link_key} for Degree Progress feed, uid = #{@uid}" unless link
      link
    end

    def massage_progresses(degree_progress)
      result = []
      if !!degree_progress
        degree_progress.each do |progress|
          if should_exclude progress
            next
          end

          result.push(progress).last.tap do |prog|
            massage_requirements prog
          end
        end
      end
      result
    end

    def massage_requirements(progress)
      requirements = normalize(progress.fetch(:requirements))
      merged_requirements = merge(requirements)
      progress[:requirements] = merged_requirements
    end

    def should_exclude(progress)
      CAREER_LAW == progress[:acadCareer] && ACAD_PROG_CODE_LACAD != progress[:acadProgCode]
    end

    def normalize(requirements)
      requirements.map! do |requirement|
        name = Berkeley::GradMilestones.get_description(requirement[:code])
        if name
          requirement[:name] = name
          requirement[:status] = Berkeley::GradMilestones.get_status(requirement[:status])
          requirement
        end
      end
      requirements.compact
    end

    def merge(requirements)
      merge_candidates = []
      merged_requirements = []

      requirements.each do |requirement|
        if is_merge_candidate requirement
          merge_candidates.push requirement
        else
          merged_requirements.push requirement
        end
      end

      if merge_candidates.length > 1
        first = find_first merge_candidates
        first[:name] = Berkeley::GradMilestones.get_merged_description
        merged_requirements.unshift(first)
      elsif merge_candidates.length === 1
        merged_requirements.unshift(merge_candidates.first)
      end
      merged_requirements
    end

    def is_merge_candidate(requirement)
      is_advancement_to_candidacy = %w(AAGADVMAS1 AAGADVMAS2).include? requirement[:code]
      is_incomplete = requirement[:date].blank?

      is_incomplete && is_advancement_to_candidacy
    end

    def find_first(requirements)
      requirements.min do |first, second|
        first[:number] <=> second[:number]
      end
    end
  end
end
