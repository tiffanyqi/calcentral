describe Eft::MyEftEnrollment do
  let (:uid) { '12345678' }
  let (:fake_model) { Eft::MyEftEnrollment.new(uid, fake: true) }
  let (:real_model) { Eft::MyEftEnrollment.new(uid, fake: false) }
  let (:eft_uri) { URI.parse(Settings.eft_proxy.base_url) }

  describe 'proper caching behaviors' do
    before do
      # Avoid caching student ID checks.
      allow_any_instance_of(Eft::MyEftEnrollment).to receive(:lookup_student_id).and_return(12345678)
    end

    context 'on success' do
      subject { fake_model }
      it 'should write to cache' do
        subject.get_feed_as_json
      end
    end

    context 'server 404s' do
      subject { real_model }
      before do
        stub_request(:any, /.*#{eft_uri.hostname}.*/).to_return(status: 404)
      end
      after { WebMock.reset! }
      it 'should write to cache' do
        subject.get_feed_as_json
      end
    end

    context 'disabled feature flag' do
      subject { fake_model }
      before do
        Settings.features.stub(:cs_billing).and_return(false)
      end
      it 'returns an empty feed' do
        feed = subject.get_feed_as_json
        expect(feed).to eq '{}'
      end
    end

  end

  describe '#get_parsed_response' do

    context 'fetching fake data feed' do
      subject { fake_model.get_parsed_response }

      it_behaves_like 'a polite HTTP client'

      it 'has correctly parsed JSON' do
        expect(subject[:statusCode]).to eq 200
        expect(subject["data"]["transaction-status"]).to eq "Confirmed"
      end

    end

    context 'server 404s' do
      before do
        stub_request(:any, /.*#{eft_uri.hostname}.*/).to_return(status: 404)
      end
      subject { real_model.get_parsed_response }
      it 'returns the expected data' do
        expect(subject[:body]).to eq('No EFT data could be found for your account.')
        expect(subject[:statusCode]).to eq 404
      end
    end

  end

end
