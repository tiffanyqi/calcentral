describe CampusSolutions::LinkController do
  context 'link feed' do
    let(:feed) { :get }

    it_behaves_like 'an unauthenticated user'

    context 'authenticated user' do
      let(:user_id) { '12345' }
      let(:feed_key) { 'link' }
      let(:urlId) { "UC_CX_TEST_LINK" }
      let(:placeholder) { "Some placeholder text" }

      before { session['user_id'] = user_id }

      it 'returns empty feed when urlId param not specified' do
        get feed, {:format => 'json'}
        expect(response.status).to eq 200

        json_response = JSON.parse(response.body)
        expect(json_response["feed"]["link"]).to_not be
      end

      it 'returns link feed with matching urlId' do
        get feed, {:urlId => urlId, :format => 'json'}
        expect(response.status).to eq 200

        json_response = JSON.parse(response.body)
        expect(json_response["feed"]["link"]["urlId"]).to eq urlId
        # Verify placeholder text is not replaced when options param omitted.
        expect(json_response["feed"]["link"]["url"]).to include("PLACEHOLDER={PLACEHOLDER}")
      end

      it 'returns link feed with matching urlId and replaced options key-values' do
        get feed, {:urlId => urlId, :options => { PLACEHOLDER: placeholder}, :format => 'json'}
        expect(response.status).to eq 200

        json_response = JSON.parse(response.body)
        expect(json_response["feed"]["link"]["urlId"]).to eq urlId
        expect(json_response["feed"]["link"]["properties"].count).to eq 2
        # Verify placeholder is replaced by options param entry.
        expect(json_response["feed"]["link"]["url"]).to include("PLACEHOLDER=#{placeholder}")
      end

    end
  end
end
