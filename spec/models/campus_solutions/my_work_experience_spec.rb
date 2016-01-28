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

      context 'attempting to transform an incorrectly formatted date' do
        let(:date) {'08-31-2012'}
        subject { proxy.cs_date_formatter date }
        it 'should return the original date format' do
          expect(subject).to eq '08-31-2012'
        end
      end

      context 'attempting to transform an empty string' do
        let(:date) {''}
        subject { proxy.cs_date_formatter date }
        it 'should return an empty string' do
          expect(subject).to eq ''
        end
      end

      context 'attempting to transform an invalid string' do
        let(:date) {'ABCDEFGHIJKLMNOP'}
        subject { proxy.cs_date_formatter date }
        it 'should return the original string' do
          expect(subject).to eq 'ABCDEFGHIJKLMNOP'
        end
      end

  end

end
