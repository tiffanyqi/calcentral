describe CampusSolutions::MyWorkExperience do

  let(:user_id) {'12351'}

  context 'post' do
    let(:params) { {} }
    let(:proxy) { CampusSolutions::MyWorkExperience.new(fake: true, user_id: user_id, params: params) }

      context 'transforming %m/%d/%Y to %Y-%m-%d' do
        let(:date) {'01/02/2012'}
        subject { proxy.cs_date_formatter date }
        it 'should correctly transform the date format' do
          expect(subject).to eq '2012-01-02'
        end
      end

      context 'attempting to transform an empty string' do
        let(:date) {''}
        subject {proxy.cs_date_formatter date}
        it 'should return an empty string' do
          expect(subject).to eq ''
        end
      end

      context 'attempting to transform an incorrectly formatted date' do
        let(:date) {'08-09-2014'}
        subject { proxy.cs_date_formatter date }
        it 'should return 400 response' do
          expect(subject).to eq false
        end
      end

      context 'attempting to post an incorrectly formatted date' do
        let(:params) { {
          sequenceNbr: '',
          employmentDescr: 'Petting Zoo',
          country: 'USA',
          city: 'ventura',
          state: 'CA',
          phone: '1234',
          startDt: '11.12.2012',
          endDt: '12.11.2013',
          titleLong: 'Test Title',
          employFrac: '10',
          hoursPerWeek: '4',
          endingPayRate: '10000',
          currencyType: 'USD',
          payFrequency: 'M'
        } }
        subject { proxy.update params }
        it 'should return a 400 response' do
          expect(subject[:statusCode]).to eq 400
          expect(subject[:errored]).to eq true
          expect(subject[:feed][:errmsgtext]).to eq 'Invalid date format.'
        end
      end

  end

end
