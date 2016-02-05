describe CampusSolutions::MyDelegateAccess do

  context '#update' do
    let(:user_id) { random_id }
    let(:feed) { { success: true } }
    subject { CampusSolutions::MyDelegateAccess.from_session({ 'user_id' => user_id }) }
    before do
      expect(CampusSolutions::DelegateAccessCreate).to receive(:new).with(user_id: user_id, params: {}).once.and_return double(get: feed)
    end
    it 'should return feed after update' do
      expect(subject.update).to eq feed
    end
  end

end
