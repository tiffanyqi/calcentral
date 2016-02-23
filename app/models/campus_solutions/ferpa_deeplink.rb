module CampusSolutions
  class FerpaDeeplink < Proxy

    include CampusSolutionsIdRequired

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def xml_filename
      'ferpa_deeplink_url.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      response.parsed_response
    end

    def url
      "#{@settings.base_url}/UC_CC_STDNT_FERPA.v1/FERPA/GET?EMPLID=#{@campus_solutions_id}"
    end

  end
end
