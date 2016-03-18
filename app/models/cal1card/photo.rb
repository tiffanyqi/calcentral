module Cal1card
  class Photo < UserSpecificModel
    include Cache::CachedFeed
    include Cache::FeedExceptionsHandled
    include Proxies::HttpClient
    include Proxies::Mockable

    def initialize(uid, options={})
      super(uid, options)
      @settings = Settings.cal1card_proxy
      @fake = (options[:fake] != nil) ? options[:fake] : @settings.fake
      initialize_mocks if @fake
    end

    def instance_key
      Cache::KeyGenerator.per_view_as_type @uid, @options
    end

    def get_feed_internal
      if Settings.features.cal1card
        get_photo
      else
        {}
      end
    end

    def get_photo
      logger.info "Fake = #{@fake}; Making request to #{url} on behalf of user #{@uid}; cache expiration #{self.class.expires_in}"
      response = get_response(
        url,
        query: {uid: @uid},
        basic_auth: {username: @settings.username, password: @settings.password},
        on_error: {rescue_status: 404}
      )
      if response.code == 404
        logger.debug "404 response from Cal1card photo API for user #{@uid}"
        {}
      else
        photo = response.parsed_response
        {
          length: photo.length.to_s,
          photo: photo
        }
      end
    end

    def url
      "#{@settings.base_url}/csc_img.asp"
    end

    def mock_request
      super.merge({
        uri_matching: url,
        query: {uid: @uid}
      })
    end

    def mock_response
      {
        status: 200,
        headers: {'Content-Type' => 'application/jpeg'},
        body: File.open(Rails.root.join('public', 'dummy', 'images', 'sample_student_72x96.jpg'), 'rb').read
      }
    end
  end
end
