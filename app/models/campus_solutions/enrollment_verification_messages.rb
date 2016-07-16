module CampusSolutions
  class EnrollmentVerificationMessages < GlobalCachedProxy

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def xml_filename
      'enrollment_verification_messages.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      response.parsed_response
    end

    def url
      "#{@settings.base_url}/UC_CC_MESSAGE_CATALOG.v1/get?MESSAGE_SET_NBR=32500"
    end

  end
end
