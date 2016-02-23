describe CampusSolutions::WorkExperienceDelete do

  let(:user_id) { '12345' }

  context 'deleting work_experience' do
    let(:params) { {} }
    let(:proxy) {CampusSolutions::WorkExperienceDelete.new(fake: true, user_id: user_id, params: params) }

    context 'converting params to Campus Solutions field names' do
      let(:params) { {
        bogus: 'foo',
        sequenceNbr: '1'
      } }
      subject {
        proxy.construct_cs_post(params)
      }
      it 'should convert the CalCentral params to Campus Solutions params without exploding on bogus fields' do
        expect(subject[:query][:SEQUENCE_NBR]).to eq '1'
        expect(subject[:query].keys.length).to eq 2
      end
    end

    context 'performing a delete' do
      let(:params) { {
        sequenceNbr: '1'
      } }
      subject {
        proxy.get
      }
      it_should_behave_like 'a simple proxy that returns errors'
      it_behaves_like 'a proxy that properly observes the profile feature flag'
      it_behaves_like 'a proxy that got data successfully'
    end
  end

  context 'with a real external service', testext: true, ignore: true  do
    let(:params) { {
      sequenceNbr: '1',
      extOrganizationId: '9000000008',
      isRetired: 'N',
      workExpAddrType: 'NONE',
      country: 'USA',
      addressType: 'HOME',
      city: 'ventura',
      state: 'CA',
      phoneType: '',
      phone: '1234',
      startDt: '2012-08-11',
      endDt: '2015-08-11',
      retirementDt: '',
      titleLong: 'Test Title',
      employFrac: '10',
      hoursPerWeek: '4',
      endingPayRate: '10000',
      currencyCd: 'USD',
      payFrequency: 'M'
    } }
    before {
      CampusSolutions::WorkExperience.new(fake: false, user_id: user_id, params: params).get
    }

    let(:proxy) { CampusSolutions::WorkExperienceDelete.new(fake: false, user_id: user_id, params: params) }
    subject { proxy.get }

    context 'a successful delete' do
      let(:params) { {
        sequenceNbr: '1'
      } }
      context 'performing a real delete' do
        it_behaves_like 'a proxy that got data successfully'
      end
    end

  end
end
