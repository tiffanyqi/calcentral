describe MyAcademicsController do

  it_should_behave_like 'a user authenticated api endpoint' do
    let(:make_request) { get :get_feed }
  end

  it 'should get a non-empty feed for an authenticated (but fake) user' do
    session['user_id'] = '0'
    get :get_feed
    json_response = JSON.parse(response.body)
    expect(json_response['regblocks']['noStudentId']).to eq true
  end

  context 'fake campus data', if: CampusOracle::Connection.test_data? do
    let(:uid) { '61889' }
    before do
      # Initialize the Profile feed last to test regressions of CLC-6141.
      fake_profile_class = Bearfacts::Profile
      fake_classes = Bearfacts::Proxy.subclasses + [ Regstatus::Proxy ]
      fake_classes.each do |klass|
        allow(klass).to receive(:new).and_return klass.new(user_id: uid, fake: true) unless klass == fake_profile_class
      end
      allow(fake_profile_class).to receive(:new).and_return fake_profile_class.new(user_id: uid, fake: true)
      session['user_id'] = uid
    end
    subject do
      get :get_feed
      JSON.parse response.body
    end
    context 'normal user session' do
      it 'should get a feed full of content' do
        expect(subject['feedName']).to eq 'MyAcademics::Merged'
        expect(subject['gpaUnits']).to include 'cumulativeGpa'
        expect(subject['otherSiteMemberships']).to be_present
        expect(subject['regblocks']).to be_present
        expect(subject['requirements']).to be_present
        expect(subject['semesters']).to have(24).items
        expect(subject['semesters'][0]['slug']).to be_present
        expect(subject['semesters'][1]['classes'][0]['transcript'][0]['grade']).to be_present
        expect(subject['transitionTerm']).to be_present
      end
    end
    context 'advisor view-as' do
      include_context 'advisor view-as'
      it 'filters bCourses sites' do
        expect(subject['otherSiteMemberships']).to be_blank
        expect(subject['feedName']).to eq 'MyAcademics::Merged'
        expect(subject['gpaUnits']).to include 'cumulativeGpa'
        expect(subject['regblocks']).to be_present
        expect(subject['requirements']).to be_present
        expect(subject['semesters']).to have(24).items
        expect(subject['semesters'][0]['slug']).to be_present
        expect(subject['semesters'][1]['classes'][0]['transcript'][0]['grade']).to be_present
        expect(subject['transitionTerm']).to be_present
      end
    end
    context 'user with teaching assignments' do
      let(:uid) {'904715'}
      context 'logged in directly' do
        it 'includes teaching-related data' do
          expect(subject['teachingSemesters']).to be_present
        end
      end
      context 'advisor view-as' do
        include_context 'advisor view-as'
        it 'excludes teaching-related data' do
          expect(subject['teachingSemesters']).to be_blank
        end
      end
    end
    context 'delegate view' do
      include_context 'delegated access'
      let(:campus_solutions_id) {'24363318'}
      context 'no academics-related permissions' do
        let(:privileges) do
          {
            financial: true
          }
        end
        it 'denies all access' do
          get :get_feed
          expect(response.status).to eq 403
          expect(response.body).to eq ' '
        end
      end
      context 'permission for My Academics' do
        shared_examples 'shared academics feed' do
          it 'views most data' do
            expect(subject).not_to include 'otherSiteMemberships'
            expect(subject).not_to include 'regblocks'
            expect(subject).not_to include 'requirements'
            expect(subject['semesters']).to have(24).items
            expect(subject['semesters'][0]).not_to include 'slug'
            expect(subject['transitionTerm']).to be_present
          end
        end
        context 'can view enrollments but not grades' do
          let(:privileges) do
            {
              viewEnrollments: true
            }
          end
          include_examples 'shared academics feed'
          it 'should get a filtered feed' do
            expect(subject['gpaUnits']).not_to include 'cumulativeGpa'
            expect(subject['semesters'][1]['classes'][0]['transcript'][0]).not_to include 'grade'
          end
        end
        context 'can view grades' do
          let(:privileges) do
            {
              viewGrades: true
            }
          end
          include_examples 'shared academics feed'
          it 'should get a less filtered feed' do
            expect(subject['gpaUnits']).to include 'cumulativeGpa'
            expect(subject['semesters'][1]['classes'][0]['transcript'][0]).to include 'grade'
          end
        end
      end
    end
  end
end
