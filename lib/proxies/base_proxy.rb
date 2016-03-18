class BaseProxy
  extend Cache::Cacheable
  include ClassLogger
  include Proxies::HttpClient

  attr_accessor :fake, :settings

  def initialize(settings, options = {})
    @settings = settings
    @fake = (options[:fake] != nil) ? options[:fake] : @settings.fake
    @uid = options[:user_id]
  end

  def get_response(url, options={})
    if @settings
      if @settings.respond_to?(:http_timeout_seconds) && (http_timeout = @settings.http_timeout_seconds.to_i) > 0
        options[:timeout] = http_timeout
      end
    end
    super(url, options)
  end

end
