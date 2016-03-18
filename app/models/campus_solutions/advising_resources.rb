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
      (response && response['ROOT']) || {}
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

  end
end
