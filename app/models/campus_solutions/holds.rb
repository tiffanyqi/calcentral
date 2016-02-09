module CampusSolutions
  class Holds < Proxy

    include HoldsFeatureFlagged
    include CampusSolutionsIdRequired
    include DatedFeed

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def xml_filename
      'holds.xml'
    end

    def build_feed(response)
      return {} unless (feed = response.parsed_response) && feed['SERVICE_INDICATORS']
      feed['SERVICE_INDICATORS'].each do |indicator|
        if indicator['START_DATE']
          # Convert to a CalCentral date
          indicator['START_DATE'] = format_date(strptime_in_time_zone(indicator['START_DATE'], '%Y-%m-%d'))
        end
      end
      feed
    end

    def url
      "#{@settings.base_url}/UC_CC_SERVC_IND.v1/Servc_ind/Get?/EMPLID=#{@campus_solutions_id}"
    end

  end
end
