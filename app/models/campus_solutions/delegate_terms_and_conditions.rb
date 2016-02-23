module CampusSolutions
  class DelegateTermsAndConditions < CachedProxy

    include DelegatedAccessFeatureFlagged

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def xml_filename
      'delegate_terms_and_conditions.xml'
    end

    def build_feed(response)
      return {} if response.parsed_response.blank?
      feed = response.parsed_response
      {
        terms_and_conditions: feed['ROOT']['GET_MESSAGE_CAT_DEFN']['DESCRLONG'].strip
      }
    end

    def url
      "#{@settings.base_url}/UC_CC_MESSAGE_CATALOG.v1/get?MESSAGE_SET_NBR=25000&MESSAGE_NBR=15"
    end

  end
end
