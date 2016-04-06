describe AdvisingStudentController do

  let(:session_user_id) { nil }
  let(:session_user_is_advisor) { false }
  let(:session_user_attributes) { { roles: { advisor: session_user_is_advisor } } }
  let(:student) { false }
  let(:ex_student) { false }
  let(:applicant) { false }
  let(:student_uid) { random_id }
  let(:student_attributes) { { roles: { student: student, exStudent: ex_student, applicant: applicant } } }
  let(:academics) { { requirements: { name: 'UC Entry Level Writing', status: 'met' } } }

  before do
    session['user_id'] = session_user_id
    allow(User::AggregatedAttributes).to receive(:new).with(student_uid).and_return double get_feed: student_attributes
    allow(User::AggregatedAttributes).to receive(:new).with(session_user_id).and_return double get_feed: session_user_attributes
  end

  context 'no user in session' do
    subject { get :profile, student_uid: student_uid }
    it 'should return empty json' do
      expect(JSON.parse subject.body).to be_empty
    end
  end

  describe '#academics' do
    let(:session_user_id) { random_id }
    before do
      allow(MyAcademics::Merged).to receive(:new).with(student_uid).and_return double get_feed: academics
    end
    subject { get :academics, student_uid: student_uid }

    context 'cannot view_as for all UIDs' do
      it 'should raise an error' do
        expect(subject.status).to eq 403
      end
    end
    context 'requested user must be a student' do
      let(:session_user_is_advisor) { true }

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
          expect(feed[:academics]).to eq academics
        end
      end
      context 'ex-student' do
        let(:ex_student) { true }
        it 'should fail' do
          expect(subject.status).to eq 403
        end
      end
      context 'applicant' do
        let(:applicant) { true }
        it 'should succeed' do
          expect(subject.status).to eq 200
          feed = JSON.parse(subject.body).deep_symbolize_keys
          expect(feed[:academics]).to eq academics
        end
      end
    end
  end

  describe '#profile' do
    let(:session_user_id) { random_id }
    before do
      allow(HubEdos::Contacts).to receive(:new).and_return double get: {}
    end
    subject { get :profile, student_uid: student_uid }

    context 'student' do
      let(:session_user_is_advisor) { true }
      let(:student) { true }
      it 'should succeed' do
        expect(subject.status).to eq 200
        feed = JSON.parse(subject.body).deep_symbolize_keys
        expect(feed[:attributes]).to eq student_attributes
      end
    end
  end

end
