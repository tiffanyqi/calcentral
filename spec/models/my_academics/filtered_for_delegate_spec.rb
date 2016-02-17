describe MyAcademics::FilteredForDelegate do
  let(:provider_classes) do
    [
      MyAcademics::CollegeAndLevel,
      MyAcademics::TransitionTerm,
      MyAcademics::GpaUnits,
      MyAcademics::Semesters,
      MyAcademics::Exams
    ]
  end

  let(:uid) { '61889' }

  before do
    allow(Settings.features).to receive(:cs_delegated_access).and_return(is_feature_enabled)
    fake_classes = Bearfacts::Proxy.subclasses + [ Regstatus::Proxy ]
    fake_classes.each do |klass|
      allow(klass).to receive(:new).and_return klass.new(user_id: uid, fake: true)
    end
    campus_solutions_id = random_id
    response = {
      feed: {
        students: [
          {
            campusSolutionsId: campus_solutions_id,
            uid: uid,
            privileges: {
              financial: false,
              viewEnrollments: view_enrollments,
              viewGrades: view_grades,
              phone: false
            }
          }
        ]
      }
    }
    proxy = double lookup_campus_solutions_id: campus_solutions_id
    expect(CalnetCrosswalk::ByUid).to receive(:new).with(user_id: uid).at_least(:once).and_return proxy
    expect(CampusSolutions::DelegateStudents).to receive(:new).once.and_return double get: response
  end
  let(:feed) { JSON.parse described_class.new(uid).get_feed_as_json }

  shared_examples 'filtered feed' do
    it 'should include expected components' do
      expect(feed['collegeAndLevel']).to be_present
      expect(feed['transitionTerm']).to be_present
      expect(feed['semesters']).to be_present
      expect(feed['examSchedule']).to be_present
    end
  end

  context 'when feature is not enabled' do
    let(:is_feature_enabled) { false }
    let(:view_enrollments) { true }
    let(:view_grades) { true }
    it 'should get nothing' do
      expect(feed.keys).to be_empty
    end
  end

  context 'when delegate permissions include grades', if: CampusOracle::Connection.test_data?  do
    let(:is_feature_enabled) { true }
    let(:view_enrollments) { true }
    let(:view_grades) { true }
    include_examples 'filtered feed'

    it 'should return grades' do
      expect(feed['gpaUnits']).to include 'cumulativeGpa'
      feed['semesters'].each do |semester|
        semester['classes'].each do |course|
          expect(course['transcript'].first).to include 'grade'
        end
      end
    end
  end

  context 'when delegate permissions do not include grades', if: CampusOracle::Connection.test_data? do
    let(:is_feature_enabled) { true }
    let(:view_enrollments) { true }
    let(:view_grades) { false }
    include_examples 'filtered feed'

    it 'should not return grades' do
      expect(feed['gpaUnits']).not_to include 'cumulativeGpa'
      feed['semesters'].each do |semester|
        semester['classes'].each do |course|
          expect(course['transcript'].first).not_to include 'grade'
        end
      end
    end
  end
end
