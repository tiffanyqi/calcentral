describe ViewAsAuthorization do

  let(:filter) { Class.new { extend ViewAsAuthorization } }
  let(:can_view_as_for_all_uids) { false }
  let(:policy) { double(can_view_as_for_all_uids?: can_view_as_for_all_uids) }
  let(:current_user) { double real_user_id: random_id, policy: policy }
  let(:is_advisor) { false }
  before {
    allow(User::AggregatedAttributes).to receive(:new).with(current_user.real_user_id).and_return double get_feed: { roles: { advisor: is_advisor } }
  }

  describe '#authorize_user_lookup' do
    let(:student_uid) { random_id }
    let(:is_student) { false }
    before {
      allow(User::AggregatedAttributes).to receive(:new).with(student_uid).and_return double get_feed: { roles: { student: is_student } }
    }
    subject { filter.authorize_user_lookup current_user, student_uid }

    context 'non-advisor looking up student' do
      let(:is_student) { true }
      it 'should fail' do
        expect{ subject }.to raise_error
      end
    end
    context 'advisor looking up non-student' do
      let(:is_advisor) { true }
      it 'should fail' do
        expect{ subject }.to raise_error
      end
    end
    context 'super-user' do
      let(:can_view_as_for_all_uids) { true }
      it 'should pass' do
        expect{ subject }.to_not raise_error
      end
    end
    context 'advisor looking up student' do
      let(:is_advisor) { true }
      let(:is_student) { true }
      it 'should pass' do
        expect{ subject }.to_not raise_error
      end
    end
  end

  describe '#authorize_query_stored_users' do
    subject { filter.authorize_query_stored_users current_user }
    context 'ordinary user' do
      it 'should fail' do
        expect{ subject }.to raise_error
      end
    end
    context 'advisor' do
      let(:is_advisor) { true }
      it 'should pass' do
        expect{ subject }.to_not raise_error
      end
    end
    context 'super-user' do
      let(:can_view_as_for_all_uids) { true }
      it 'should pass' do
        expect{ subject }.to_not raise_error
      end
    end
  end

end
