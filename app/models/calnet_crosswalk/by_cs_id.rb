module CalnetCrosswalk
  class ByCsId < Proxy

    def url
      "#{@settings.base_url}/CAMPUS_SOLUTIONS_ID/#{@uid}"
    end

    def mock_request
      super.merge(uri_matching: "#{@settings.base_url}/CAMPUS_SOLUTIONS_ID/#{@uid}")
    end

  end
end
