module CampusSolutions
  class AdvisingResources < CachedProxy

    include CampusSolutionsIdRequired
    include Cache::RelatedCacheKeyTracker

    def initialize(options = {})
      @student = {
        uid: options[:student_uid]
      }
      super options
    end

    def get_internal
      lookup_student_id
      if @student[:uid] && !@student[:campus_solutions_id]
        logger.info "Lookup of campus_solutions_id for uid #{@student[:uid]} failed, cannot call Campus Solutions API"
        {
          noStudentId: true
        }
      else
        super
      end
    end

    def lookup_student_id
      if @student[:uid]
        @student[:campus_solutions_id] = CalnetCrosswalk::ByUid.new(user_id: @student[:uid]).lookup_campus_solutions_id
      end
    end

    def build_feed(response)
      return {} unless response && (feed = response['ROOT'])
      links = (resources = feed['UC_ADVISING_RESOURCES']) && resources['UC_ADVISING_LINKS']
      if links
        # The following links are hard-coded, for now. Ideally they would be served by CS API but there is an urgent need
        # thus we manage the content via CalCentral settings.
        add_cs_link links, :multi_year_academic_planner, 'Multi-Year Academic Planner'
        add_cs_link links, :schedule_planner, 'Schedule Planner'
        add_cs_link links, :multi_year_academic_planner_student_specific, 'Multi-Year Academic Planner'
        add_cs_link links, :schedule_planner_student_specific, 'Schedule Planner'
      end
      feed
    end

    def instance_key
      [@uid, @student[:uid]].compact.join '-'
    end

    def url
      "#{@settings.base_url}/UC_AA_ADVISING_RESOURCES.v1/UC_ADVISING_RESOURCES?EMPLID=#{@campus_solutions_id}".tap do |url|
        url << "&STUDENT_EMPLID=#{@student[:campus_solutions_id]}" if @student[:campus_solutions_id]
      end
    end

    def xml_filename
      'advising_resources.xml'
    end

    private

    def add_cs_link(links, key, name)
      value = Settings.campus_solutions_links.advising.send key
      if value
        links[key.to_s.upcase] = {
          'NAME' => name,
          'URL' => value,
          'IS_CS_LINK' => true
        }
      end
    end

  end
end
