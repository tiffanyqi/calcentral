module CampusSolutions
  class FppEnrollment < GlobalCachedProxy

    include BillingFeatureFlagged

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def xml_filename
      'fpp_enrollment.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      response.parsed_response
    end

    #TODO: Replace with actual API endpoint when ready.
    def url
      "#{@settings.base_url}/UC_FPP_ENROLLMENT_API.v1/UC_FPP_ENROLLMENT_API_GET"
    end

  end
end
