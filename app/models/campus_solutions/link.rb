module CampusSolutions
  class Link < GlobalCachedProxy

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def xml_filename
      'link_api.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      normalize_response(response)
    end

    def normalize_response(response)
      # Make sure response is well-structured.
      container = response.parsed_response
      return container if container['UC_LINK_RESOURCES'].blank? || container['UC_LINK_RESOURCES']['IS_FAULT'].present?
      # Insert Links element array.
      container['UC_LINK_RESOURCES']['Links'] = Array.wrap container['UC_LINK_RESOURCES']['Link']
      container
    end

    def get_url(urlId, options = {})
      # get cached response
      response = get
      links = response[:feed][:ucLinkResources][:links]
      link = links.find do |link|
        link[:urlId] == urlId
      end
      if link && options.any?
        options.each do |k, v|
          link[:url] = link[:url].gsub("{#{k}}", v)
        end
      end
      response[:feed] = { :link => link }
      response
    end

    def def url
      "#{@settings.base_url}/UC_LINK_API.v1/get?PROPNAME=UC_CX_LINK"
    end

  end
end
