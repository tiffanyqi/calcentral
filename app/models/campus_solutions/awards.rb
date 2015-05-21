module CampusSolutions
  class Awards < IntegrationHubProxy

    def initialize(options = {})
      super(Settings.cs_awards_proxy, options)
      initialize_mocks if @fake
    end

    def xml_filename
      'cs_awards.xml'
    end

  end
end
