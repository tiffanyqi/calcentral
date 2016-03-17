describe CampusSolutions::BillingController do

  let(:user_id) { '12345' }

  context 'billing feed' do
    let(:feed) { :get }
    it_behaves_like 'an unauthenticated user'

    context 'authenticated user' do
      let(:feed_key) { 'ucSfActivity' }
      it_behaves_like 'a successful feed'
      it 'has some field mapping info' do
        session['user_id'] = user_id
        get feed
        json = JSON.parse(response.body)
        expect(json['feed']['ucSfActivity']['activity'][0]['itemDescription']).to eq 'Room and board'
      end
    end
  end

end
