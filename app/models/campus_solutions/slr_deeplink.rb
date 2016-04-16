module CampusSolutions
  class SLRDeeplink < Proxy

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def xml_filename
      'slr_deeplink.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      response.parsed_response
    end

    def url
      "#{@settings.base_url}/UC_SR_SLR_LINKS.v1/UC_SR_SLR_LINKS_GET"
    end

  end
end
