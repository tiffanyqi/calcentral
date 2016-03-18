module CampusSolutions
  class Billing < Proxy

    include BillingFeatureFlagged
    include CampusSolutionsIdRequired

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def xml_filename
      'billing_details.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      response.parsed_response
    end

    #TODO Placeholder URL for development.
    def url
      "#{@settings.base_url}/BILLING_API/get?EMPLID=#{@campus_solutions_id}&INSTITUTION=UCB01"
    end

  end
end
