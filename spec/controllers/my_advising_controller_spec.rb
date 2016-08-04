describe MyAdvisingController do

  describe '#get_feed' do
    context 'no authenticated user' do
      it 'should return empty' do
        get :get_feed
        assert_response :success
        expect(JSON.parse response.body).to be_empty
      end
    end

    context 'authenticated user' do
      before { session['user_id'] = '61889' }
      it 'should return a feed full of content' do
        get :get_feed
        json_response = JSON.parse(response.body)
        expect(json_response['statusCode']).to eq 200
        expect(json_response['feed']['actionItems']).to be
        expect(json_response['feed']['advisors']).to be
        expect(json_response['feed']['appointments']).to be
        expect(json_response['feed']['links']).to be
      end
    end
  end

  describe '#get_legacy_feed' do
    context 'no authenticated user' do
      it 'should return empty' do
        get :get_legacy_feed
        assert_response :success
        expect(JSON.parse response.body).to be_empty
      end
    end

    context 'authenticated user' do
      before do
        allow(Settings.advising_proxy).to receive(:fake).and_return(true)
        session['user_id'] = '61889'
      end
      it 'should be an non-empty advising feed based on fake Oski recorded data' do
        get :get_legacy_feed
        assert_response :success
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq 6
        expect(json_response['statusCode']).to eq 200
      end
    end
  end
end
