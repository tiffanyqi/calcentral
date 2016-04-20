describe BaseProxy do
  before {
    allow_any_instance_of(Proxies::HttpClient).to receive(:get_response).and_return double
  }
  subject {
    BaseProxy.new(settings, fake: true).get_response 'http://www.this-URL-is-not-used.com', (options = {})
    options[:timeout]
  }

  context 'a proxy class can have its own custom HTTP settings' do
    context 'actual YAML' do
      let(:settings) { Settings.hub_edos_proxy }
      it { should be_an Integer }
      it { should be > 0 }
    end

    context 'proper settings' do
      let(:settings) { double http_timeout_seconds: timeout_setting }
      context 'http_timeout is nil' do
        let(:timeout_setting) { nil }
        it { should be nil }
      end
      context 'http_timeout is blank' do
        let(:timeout_setting) { '  ' }
        it { should be nil }
      end
      context 'http_timeout is an integer' do
        let(:timeout_setting) { ' 60 ' }
        it { should eq 60 }
      end
      context 'http_timeout is a float' do
        let(:timeout_setting) { 10 }
        it { should eq 10 }
      end
    end

    context 'missing or invalid settings' do
      context 'nil settings' do
        let(:settings) { nil }
        it { should be nil }
      end
      context 'unexpected settings type' do
        let(:settings) { '' }
        it { should be nil }
      end
    end
  end

end
