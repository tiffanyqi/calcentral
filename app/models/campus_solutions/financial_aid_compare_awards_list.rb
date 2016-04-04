module CampusSolutions
  class FinancialAidCompareAwardsList < Proxy

    include FinancialAidCompareAwardsFeatureFlagged
    include CampusSolutionsIdRequired
    include DatedFeed

    def initialize(options = {})
      super options
      @aid_year = options[:aid_year]
      initialize_mocks if @fake
    end

    def xml_filename
      'financial_aid_compare_awards_list.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      feed = response.parsed_response['ROOT'] || response.parsed_response[error_response_root_xml_node] || {}

      feed['AWARD_PARMS']['DATA'] = feed['AWARD_PARMS']['DATA'].sort.reverse.map do |label|
        {
           csDate: label,
           date: format_date(strptime_in_time_zone(label, '%Y-%m-%d-%H.%M.%S'))
        }
      end

      feed
    end

    def url
      "#{@settings.base_url}/UC_FA_AWARD_COMPARE_PARMS.v1/get?EMPLID=#{@campus_solutions_id}&AID_YEAR=#{@aid_year}"
    end

  end
end
