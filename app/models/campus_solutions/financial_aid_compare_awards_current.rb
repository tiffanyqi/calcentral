module CampusSolutions
  class FinancialAidCompareAwardsCurrent < Proxy

    include FinancialAidCompareAwardsFeatureFlagged
    include CampusSolutionsIdRequired

    def initialize(options = {})
      super options
      @aid_year = options[:aid_year]
      initialize_mocks if @fake
    end

    def xml_filename
      'financial_aid_compare_awards_current.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      response.parsed_response['ROOT'] || response.parsed_response[error_response_root_xml_node] || {}
    end

    def url
      "#{@settings.base_url}/UC_FA_AWARD_COMPARE_CURRNT.v1/get?EMPLID=#{@campus_solutions_id}&AID_YEAR=#{@aid_year}"
    end

  end
end
