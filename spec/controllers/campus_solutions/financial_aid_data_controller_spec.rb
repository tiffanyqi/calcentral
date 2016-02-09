describe CampusSolutions::FinancialAidDataController do

  let(:user_id) { '12345' }

  context 'financial data feed' do
    let(:feed) { :get }
    let(:options) { {aid_year: '2016', format: 'json'} }

    context 'unauthenticated user' do
      it 'returns 401' do
        get feed, options
        expect(response.status).to eq 401
      end
    end

    context 'authenticated user' do
      before { session['user_id'] = user_id }
      it 'has some field mapping info' do
        get feed, options
        json = JSON.parse response.body
        expect(json['feed']['coa']['title']).to eq 'Estimated Cost of Attendance'
      end

      context 'no aid year provided' do
        let(:options) { {format: 'json'} }
        it 'returns empty' do
          get feed, options
          json = JSON.parse response.body
          expect(json).not_to include 'feed'
        end
      end
    end

    context 'advisor session' do
      let(:filtered_feed) { { key: 'value' } }
      before {
        session['user_id'] = user_id
        session['original_advisor_user_id'] = random_id
        model = double(get_feed_as_json: filtered_feed)
        expect(model).to receive(:aid_year=).with '2016'
        expect(CampusSolutions::MyFinancialAidFilteredForAdvisor).to receive(:from_session).once.and_return model
        expect(CampusSolutions::MyFinancialAidData).to_not receive :from_session
      }
      it 'invokes the filtered feed when advisor-view-as mode' do
        get feed, options
        json = JSON.parse response.body
        expect(json['key']).to eq 'value'
      end
    end
  end

end
