describe User::Api do
  before(:each) do
    @random_id = Time.now.to_f.to_s.gsub('.', '')
    @preferred_name = 'Sid Vicious'
    allow(HubEdos::UserAttributes).to receive(:new).and_return double get:  {
      person_name: @preferred_name,
      student_id: '1234567890',
      campus_solutions_id: 'CC12345678',
      official_bmail_address: 'foo@foo.com',
      roles: {
        student: true,
        exStudent: false,
        faculty: false,
        staff: false
      }
    }
  end

  it 'should find user with default name' do
    u = User::Api.new @random_id
    u.init
    expect(u.preferred_name).to eq @preferred_name
  end
  it 'should override the default name' do
    u = User::Api.new @random_id
    u.update_attributes preferred_name: 'Herr Heyer'
    u = User::Api.new @random_id
    u.init
    expect(u.preferred_name).to eq 'Herr Heyer'
  end
  it 'should revert to the default name' do
    u = User::Api.new @random_id
    u.update_attributes preferred_name: 'Herr Heyer'
    u = User::Api.new @random_id
    u.update_attributes preferred_name: ''
    u = User::Api.new @random_id
    u.init
    expect(u.preferred_name).to eq @preferred_name
  end
  it 'should return a user data structure' do
    user_data = User::Api.new(@random_id).get_feed
    expect(user_data[:preferred_name]).to eq @preferred_name
    expect(user_data[:hasCanvasAccount]).to_not be_nil
    expect(user_data[:isCalendarOptedIn]).to_not be_nil
    expect(user_data[:isCampusSolutionsStudent]).to be true
    expect(user_data[:showSisProfileUI]).to be true
    expect(user_data[:hasToolboxTab]).to be false
    expect(user_data[:officialBmailAddress]).to eq 'foo@foo.com'
    expect(user_data[:campusSolutionsID]).to eq 'CC12345678'
    expect(user_data[:sid]).to eq '1234567890'
  end

  context 'with a legacy student' do
    let(:user_data) { User::Api.new(@random_id).get_feed }
    before do
      expect(HubEdos::UserAttributes).to receive(:new).and_return(
        double(
          get: {
            :person_name => @preferred_name,
            :campus_solutions_id => '12345678', # 8-digit ID means legacy
            :roles => {
              :student => true,
              :exStudent => false,
              :faculty => false,
              :staff => false
            }
          }))
    end
    context 'with the fallback enabled' do
      before do
        allow(Settings.features).to receive(:cs_profile_visible_for_legacy_users).and_return false
      end
      it 'should hide SIS profile for legacy students' do
        expect(user_data[:isCampusSolutionsStudent]).to be false
        expect(user_data[:showSisProfileUI]).to be false
      end
    end
    context 'with the fallback disabled' do
      before do
        allow(Settings.features).to receive(:cs_profile_visible_for_legacy_users).and_return true
      end
      it 'should show SIS profile for legacy students' do
        expect(user_data[:isCampusSolutionsStudent]).to be false
        expect(user_data[:showSisProfileUI]).to be true
      end
    end
  end

  it 'should return whether the user is registered with Canvas' do
    expect(Canvas::Proxy).to receive(:has_account?).and_return(true, false)
    user_data = User::Api.new(@random_id).get_feed
    expect(user_data[:hasCanvasAccount]).to be true
    Rails.cache.clear
    user_data = User::Api.new(@random_id).get_feed
    expect(user_data[:hasCanvasAccount]).to be false
  end
  it 'should have a null first_login time for a new user' do
    user_data = User::Api.new(@random_id).get_feed
    expect(user_data[:firstLoginAt]).to be_nil
  end
  it 'should properly register a call to record_first_login' do
    user_api = User::Api.new @random_id
    user_api.get_feed
    user_api.record_first_login
    updated_data = user_api.get_feed
    expect(updated_data[:firstLoginAt]).to_not be_nil
  end
  it 'should delete a user and all his dependent parts' do
    user_api = User::Api.new @random_id
    user_api.record_first_login
    user_api.get_feed

    expect(User::Oauth2Data).to receive :destroy_all
    expect(Notifications::Notification).to receive :destroy_all
    expect(Cache::UserCacheExpiry).to receive :notify
    expect(Calendar::User).to receive :delete_all

    User::Api.delete @random_id

    expect(User::Data.where :uid => @random_id).to eq []
  end

  it 'should say random student gets the academics tab' do
    user_data = User::Api.new(@random_id).get_feed
    expect(user_data[:hasAcademicsTab]).to be true
  end

  it 'should say a staff member with no academic history does not get the academics tab' do
    allow(CampusOracle::UserAttributes).to receive(:new).and_return double get_feed: {
      'person_name' => @preferred_name,
      :roles => {
        :student => false,
        :faculty => false,
        :staff => true
      }
    }
    allow(CampusOracle::UserCourses::HasInstructorHistory).to receive(:new).and_return double(has_instructor_history?: false)
    allow(HubEdos::UserAttributes).to receive(:new).and_return double(get: {
      person_name: @preferred_name,
      roles: {}
    })
    user_data = User::Api.new('904715').get_feed
    expect(user_data[:hasAcademicsTab]).to eq false
  end

  describe 'My Finances tab' do
    before do
      allow(CampusOracle::UserAttributes).to receive(:new).and_return double(get_feed: {
        roles: oracle_roles
      })
      allow(HubEdos::UserAttributes).to receive(:new).and_return double(get: {
        roles: edo_roles
      })
    end
    subject { User::Api.new(@random_id).get_feed[:hasFinancialsTab] }
    context 'active student' do
      let(:oracle_roles) { { :student => true, :exStudent => false, :faculty => false, :staff => false } }
      let(:edo_roles) { { student: true } }
      it { should be true }
    end
    context 'staff' do
      let(:oracle_roles) { { :student => false, :exStudent => false, :faculty => false, :staff => true } }
      let(:edo_roles) { {} }
      it { should be false }
    end
    context 'former student' do
      let(:oracle_roles) { { :student => false, :exStudent => true, :faculty => false, :staff => false } }
      let(:edo_roles) { {} }
      it { should be true }
    end
  end

  describe 'My Toolbox tab' do
    context 'superuser' do
      before { User::Auth.new_or_update_superuser! @random_id }
      it 'should show My Toolbox tab' do
        user_api = User::Api.new @random_id
        expect(user_api.get_feed[:hasToolboxTab]).to be true
      end
    end
    context 'can_view_as' do
      before {
        user = User::Auth.new uid: @random_id
        user.is_viewer = true
        user.active = true
        user.save
      }
      subject { User::Api.new(@random_id).get_feed[:hasToolboxTab] }
      it { should be true }
    end
    context 'ordinary profiles' do
      let(:profiles) do
        {
          :student   => { :student => true,  :exStudent => false, :faculty => false, :staff => false },
          :faculty   => { :student => false, :exStudent => false, :faculty => true,  :staff => false },
          :staff     => { :student => false, :exStudent => false, :faculty => true,  :staff => true }
        }
      end
      before do
        allow(CampusOracle::UserAttributes).to receive(:new).and_return double get_feed: {
          roles: user_roles
        }
      end
      subject { User::Api.new(@random_id).get_feed[:hasToolboxTab] }
      context 'student' do
        let(:user_roles) { profiles[:student] }
        it { should be false }
      end
      context 'faculty' do
        let(:user_roles) { profiles[:faculty] }
        it { should be false }
      end
      context 'staff' do
        let(:user_roles) { profiles[:staff] }
        it { should be false }
      end
    end
  end

  context 'HubEdos errors', if: CampusOracle::Queries.test_data? do
    let(:uid) { '1151855' }
    let(:feed) { User::Api.new(uid).get_feed }

    before do
      allow(HubEdos::UserAttributes).to receive(:new).and_return double(get: badly_behaved_edo_attributes)
    end

    let(:expected_values_from_campus_oracle) {
      {
        first_name: 'Eugene V',
        last_name: 'Debs',
        preferred_name: 'Eugene V Debs',
        fullName: 'Eugene V Debs',
        uid: '1151855',
        sid: '18551926',
        isCampusSolutionsStudent: false,
        roles: {
          student: true,
          registered: true,
          exStudent: false,
          faculty: false,
          staff: false,
          guest: false,
          concurrentEnrollmentStudent: false,
          expiredAccount: false
        }
      }
    }

    shared_examples 'handling bad behavior' do
      it 'should fall back to campus Oracle' do
        expect(feed).to include expected_values_from_campus_oracle
      end
    end

    context 'empty response' do
      let(:badly_behaved_edo_attributes) { {} }
      include_examples 'handling bad behavior'
    end

    context 'ID lookup errors' do
      let(:badly_behaved_edo_attributes) do
        {
          student_id: {
            body: 'An unknown server error occurred',
            statusCode: 503
          }
        }
      end
      include_examples 'handling bad behavior'
    end

    context 'name lookup errors' do
      let(:badly_behaved_edo_attributes) do
        {
          first_name: nil,
          last_name: nil,
          person_name: {
            body: 'An unknown server error occurred',
            statusCode: 503
          }
        }
      end
      include_examples 'handling bad behavior'
    end

    context 'role lookup errors' do
      let(:badly_behaved_edo_attributes) do
        {
          roles: {
            body: 'An unknown server error occurred',
            statusCode: 503
          }
        }
      end
      include_examples 'handling bad behavior'
    end

    context 'when ex-student is incorrectly reported active' do
      let(:uid) { '2040' }
      let(:badly_behaved_edo_attributes) do
        {
          roles: {
            student: true
          }
        }
      end
      it 'should give precedence to campus Oracle on ex-student status' do
        expect(feed[:roles][:exStudent]).to eq true
        expect(feed[:roles][:student]).to eq false
      end
    end
  end

  context 'proper cache handling' do

    it 'should update the last modified hash when content changes' do
      user_api = User::Api.new @random_id
      user_api.get_feed
      original_last_modified = User::Api.get_last_modified @random_id
      old_hash = original_last_modified[:hash]
      old_timestamp = original_last_modified[:timestamp]

      sleep 1

      user_api.preferred_name = 'New Name'
      user_api.save
      feed = user_api.get_feed
      new_last_modified = User::Api.get_last_modified @random_id
      expect(new_last_modified[:hash]).to_not eq old_hash
      expect(new_last_modified[:timestamp]).to_not eq old_timestamp
      expect(new_last_modified[:timestamp][:epoch]).to eq feed[:lastModified][:timestamp][:epoch]
    end

    it 'should not update the last modified hash when content has not changed' do
      user_api = User::Api.new @random_id
      user_api.get_feed
      original_last_modified = User::Api.get_last_modified @random_id

      sleep 1

      Cache::UserCacheExpiry.notify @random_id
      feed = user_api.get_feed
      unchanged_last_modified = User::Api.get_last_modified @random_id
      expect(original_last_modified).to eq unchanged_last_modified
      expect(original_last_modified[:timestamp][:epoch]).to eq feed[:lastModified][:timestamp][:epoch]
    end

  end

  context 'proper handling of superuser permissions' do
    before { User::Auth.new_or_update_superuser! @random_id }
    subject { User::Api.new(@random_id).get_feed }
    it 'should pass the superuser status' do
      expect(subject[:isSuperuser]).to be true
      expect(subject[:isViewer]).to be true
      expect(subject[:hasToolboxTab]).to be true
    end
  end

  context 'proper handling of viewer permissions' do
    before {
      user = User::Auth.new uid: @random_id
      user.is_viewer = true
      user.active = true
      user.save
    }
    subject { User::Api.new(@random_id).get_feed }
    it 'should pass the viewer status' do
      expect(subject[:isSuperuser]).to be false
      expect(subject[:isViewer]).to be true
      expect(subject[:hasToolboxTab]).to be true
    end
  end

end
