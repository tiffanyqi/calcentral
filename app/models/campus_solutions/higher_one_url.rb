module CampusSolutions
  class HigherOneUrl < Proxy

    include SirFeatureFlagged
    include CampusSolutionsIdRequired

    def initialize(options = {})
      super(options)
      @delegate_uid = options[:delegate_uid]
      initialize_mocks if @fake
    end

    def xml_filename
      'higher_one_url.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      response.parsed_response
    end

    def url
      @delegate_cs_id ||= campus_solutions_id_by @delegate_uid
      query_args = @delegate_cs_id ? "DELEGATE_UID=#{@delegate_cs_id}" : "EMPLID=#{@campus_solutions_id}"
      "#{@settings.base_url}/UC_OB_HIGHER_ONE_URL_GET.v1/get?#{query_args}"
    end

    def campus_solutions_id_by(uid)
      uid && CalnetCrosswalk::ByUid.new(user_id: uid).lookup_campus_solutions_id
    end

  end
end
