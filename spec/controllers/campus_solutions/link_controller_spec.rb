describe CampusSolutions::LinkController do
  context 'link feed' do
    let(:feed) { :get }

    it_behaves_like 'an unauthenticated user'

    context 'authenticated user' do
      let(:user_id) { '12345' }
      let(:feed_key) { 'link' }
      let(:urlId) { "UC_CX_TEST_LINK" }

      it 'has some field mapping info' do
        get feed, {:urlId => "UC_CX_TEST_LINK", :options => { PLACEHOLDER: "some text"}, :format => 'json'}
      end
    end
  end
end
