describe Cache::KeyGenerator do

  it 'should return nil when provided cache_key is nil' do
    expect(Cache::KeyGenerator.per_view_as_type nil).to be_nil
  end

  context 'generate key per view-as type' do
    let(:cache_key) { random_id }
    subject { Cache::KeyGenerator.per_view_as_type cache_key, session }

    context 'directly authenticated' do
      let(:session) { { 'foo' => random_id, 'baz' => random_id } }
      it 'should not change cache key when there is no view-as marker' do
        expect(subject).to eq cache_key
      end
    end

    context 'view-as session' do
      let(:viewer_uid) { random_id }
      let(:session) { { 'foo' => random_id, session_key => viewer_uid, 'baz' => random_id } }

      shared_examples 'view-as session with distinct cache key' do
        it 'should customize cache key to include the name of view-as type' do
          expect(subject).to include cache_key, session_key, viewer_uid
        end
      end
      context 'masquerading in canvas' do
        let(:session_key) { SessionKey.canvas_masquerading_user_id }
        it_behaves_like 'view-as session with distinct cache key'
      end
      context 'super_user in view-as mode' do
        let(:session_key) { SessionKey.original_user_id }
        it_behaves_like 'view-as session with distinct cache key'
      end
      context 'advisor in view-as mode' do
        let(:session_key) { SessionKey.original_advisor_user_id }
        it_behaves_like 'view-as session with distinct cache key'
      end
    end
  end
end
