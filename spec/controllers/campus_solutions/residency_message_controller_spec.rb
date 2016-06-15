describe CampusSolutions::ResidencyMessageController do
  context 'residency message feed' do
    let(:feed) { :get }
    it_behaves_like 'an unauthenticated user'
    context 'authenticated user' do
      let(:user_id) { '12345' }
      let(:feed_key) { 'root' }
      it_behaves_like 'a successful feed'

      it 'has some field mapping info' do
        get feed, {:messageNbr => '2005', :format => 'json'}
      end

    end
  end
end
