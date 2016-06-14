module CampusSolutions
  class ResidencyMessage < GlobalCachedProxy

    def initialize(options = {})
      super options
      @message_nbr = options[:messageNbr]
      initialize_mocks if @fake
    end

    def xml_filename
      'residency_message.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      response.parsed_response
    end

    def instance_key
      @message_nbr
    end

    def url
      "#{@settings.base_url}/UC_CC_MESSAGE_CATALOG.v1/get?MESSAGE_SET_NBR=28001&MESSAGE_NBR=#{@message_nbr}"
    end

  end
end
