module Terms
  class Proxy  < BaseProxy
    include ClassLogger
    include Proxies::AuthenticatedApi
    include Proxies::Mockable

    def initialize(options = {})
      super(Settings.terms_proxy, options)
      # Previous, Current, or Next. Current is the default if the option is not specified.
      @temporal_position = options[:temporal_position]
      # Date from which the temporal position should be decided. Today is the default if no date is specified.
      # For example, this can be used to find the term after the next term.
      @as_of_date = options[:as_of_date]
      initialize_mocks if @fake
    end

    # Because the API takes 0, 1, or 2 parameters, the key of the corresponding instance can be
    # nil (i.e., "global"), based on one parameter, or based on both parameters.
    def instance_key
      [@temporal_position, @as_of_date].compact.join '-'
    end

    def mock_json
      filename = 'terms'
      filename.concat "_#{@temporal_position.downcase}" if @temporal_position
      filename.concat "_#{@as_of_date}" if @as_of_date
      read_file('fixtures', 'json', "#{filename}.json")
    end

    def mock_response
      response = super()
      if response[:body].blank?
        response = {
          status: 404,
          headers: {'Content-Type' => 'application/json'},
          body: "{\"apiResponse\": {\"httpStatus\": {\"code\": 404, \"description\": \"Not Found\"}, \"message\": {\"description\": \"No term found for the given date\"}}}"
        }
      end
      response
    end

    def get
      self.class.handling_exceptions(instance_key) do
        get_internal
      end
    end

    def get_internal
      response = get_response(url, request_options)
      # When the campus is between terms, a request for the 'Current' term will return 404 with a
      # "No term found" message. Since that is expected behavior, it should not be logged as an ERROR.
      # Other sorts of 404 returns (such as a bad URI path) do need attention, however.
      if response.code == 404 &&
        (!response['apiResponse'] || !response['apiResponse']['message'] ||
        response['apiResponse']['message']['description'] != 'No term found for the given date')
        logger.error "Unexpected 404 response for instance #{instance_key}: #{response}"
      else
        logger.debug "Remote server status #{response.code}, instance = #{instance_key} Body = #{response.body.force_encoding('UTF-8')}"
      end
      response
    end

    def url
      @settings.base_url
    end

    def request_options(opts = {})
      default_opts = {
        headers: {
          'Accept' => 'application/json'
        },
        on_error: {
          rescue_status: 404
        }
      }
      if @temporal_position
        default_opts[:query] = {'temporal-position' => @temporal_position}
        default_opts[:query]['as-of-date'] = @as_of_date if @as_of_date
      end
      default_opts.deep_merge super(opts)
    end

  end
end
