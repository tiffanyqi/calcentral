describe StudentOverviewController do

  let(:session_user_id) { nil }
  let(:student_uid) { random_id }
  let(:can_view_as_for_all_uids) { false }
  let(:user_attributes) { double }
  let(:academics) { { requirements: { name: 'UC Entry Level Writing', status: 'met' } } }

  before do
    session['user_id'] = session_user_id
    allow_any_instance_of(AuthenticationStatePolicy).to receive(:can_view_as_for_all_uids?).and_return can_view_as_for_all_uids
  end

  context 'no user in session' do
    subject { get :student, student_uid: student_uid }
    it 'should return empty json' do
      expect(JSON.parse subject.body).to be_empty
    end
  end

  describe '#student' do
    let(:session_user_id) { random_id }
    before do
      allow(User::AggregatedAttributes).to receive(:new).with(student_uid).and_return double get_feed: user_attributes
      allow(MyAcademics::Merged).to receive(:new).with(student_uid).and_return double get_feed: academics
      allow(MyAcademics::Exams).to receive(:new).with(student_uid).and_return double merge: double
    end
    subject { get :student, student_uid: student_uid }

    context 'cannot view_as for all UIDs' do
      it 'should raise an error' do
        expect(subject.status).to eq 403
      end
    end
    context 'requested user must be a student' do
      let(:can_view_as_for_all_uids) { true }
      let(:student) { false }
      let(:ex_student) { false }
      let(:applicant) { false }
      let(:user_attributes) { { roles: { student: student, exStudent: ex_student, applicant: applicant } } }

      context 'feature flag false' do
        let(:student) { true }
        before do
          allow(Settings.features).to receive(:cs_advisor_student_lookup).and_return false
        end
        it 'should raise an error' do
          expect(subject.status).to eq 403
        end
      end
      context 'not a student' do
        it 'should raise an error' do
          expect(subject.status).to eq 403
        end
      end
      context 'student' do
        let(:student) { true }
        it 'should succeed' do
          expect(subject.status).to eq 200
          feed = JSON.parse(subject.body).deep_symbolize_keys
          expect(feed[:attributes]).to eq user_attributes
          expect(feed[:academics]).to eq academics
        end
      end
      context 'ex-student' do
        let(:ex_student) { true }
        it 'should succeed' do
          expect(subject.status).to eq 200
          expect(JSON.parse(subject.body).deep_symbolize_keys[:attributes]).to eq user_attributes
        end
      end
      context 'applicant' do
        let(:applicant) { true }
        it 'should succeed' do
          expect(subject.status).to eq 200
          expect(JSON.parse(subject.body).deep_symbolize_keys[:attributes]).to eq user_attributes
        end
      end
    end
  end

end
