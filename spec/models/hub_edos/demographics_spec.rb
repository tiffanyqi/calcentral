describe HubEdos::Demographics do

  context 'mock proxy' do
    let(:include_fields) { nil }
    let(:proxy) { HubEdos::Demographics.new(fake: true, user_id: '61889', include_fields: include_fields) }
    subject { proxy.get }

    it_behaves_like 'a proxy that properly observes the profile feature flag'
    it_should_behave_like 'a simple proxy that returns errors'

    it 'returns data with the expected structure' do
      expect(subject[:feed]['student']).to be
      expect(subject[:feed]['student']['ethnicities'][0]['group']['code']).to eq '2'
      expect(subject[:feed]['student']['usaCountry']).to be
      expect(subject[:feed]['student']['residency']['official']).to be
      expect(subject[:feed]['student']['residency']['message']['code']).to eq "2005"
      expect(subject[:feed]['student']['residency']['fromTerm']['label']).to eq "Summer 2014"
    end

    context 'unexpected residency data' do
      before do
        residency_json = '{"source":{"code":"SelfReported - Application"},"fromDate":"2016-05-31","county":"","stateCode":"","countryCode":"USA","postalCode":"","comments":""}'
        proxy.override_json do |json|
          json['apiResponse']['response']['any']['students'].first['residency'] = JSON.parse residency_json
        end
      end
      it 'returns other data' do
        expect(subject[:feed]['student']).to be
        expect(subject[:feed]['student']['ethnicities'][0]['group']['code']).to eq '2'
        expect(subject[:feed]['student']['usaCountry']).to be
      end
    end

    it 'should return default fields only' do
      fields = subject[:feed]['student']
      %w(ethnicities usaCountry residency).each do |key|
        expect(fields[key]).to be_present
      end
      expect(fields['identifiers']).to be_blank
    end

    context 'view-as session' do
      let(:include_fields) { ['residency'] }
      it 'should return only the specified fields through the public endpoint' do
        fields = subject[:feed]['student']
        %w(ethnicities usaCountry).each do |key|
          expect(fields[key]).to be_blank
        end
        expect(fields['residency']).to be_present
      end
      describe '#get_internal' do
        it 'keeps the uncensored feed available for caching' do
          fields = proxy.get_internal[:feed]['student']
          %w(ethnicities usaCountry residency).each do |key|
            expect(fields[key]).to be_present
          end
          expect(fields['identifiers']).to be_blank
        end
      end
    end
  end

  context 'real proxy', testext: true do
    let(:proxy) { HubEdos::Demographics.new(fake: false, user_id: '61889') }
    subject { proxy.get }

    it_behaves_like 'a proxy that properly observes the profile feature flag'

    it 'returns data with the expected structure' do
      expect(subject[:feed]['student']).to be
      expect(subject[:feed]['student']['ethnicities'][0]).to be
      expect(subject[:feed]['student']['residency']).to be
    end

  end
end
