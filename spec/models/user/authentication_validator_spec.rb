require 'spec_helper'

describe User::AuthenticationValidator do
  let(:auth_uid) { random_id }
  let(:feature_flag) { true }
  before do
    allow(Settings.features).to receive(:authentication_validator).and_return(feature_flag)
  end

  describe '#held_applicant?' do
    let(:nil_calnet_row) do
      { 'affiliations' => ''}
    end
    let(:held_cs_affiliations) do
      {:statusCode=>200,
        :feed=>
          {'student'=>
            {'affiliations'=>
              [{'type'=>{'code'=>'APPLICANT', 'description'=>'Applicant'},
                'status'=> {
                  'code'=>'ACT',
                  'description'=>'Active'},
                'fromDate'=>'2016-01-06'}]}},
        :studentNotFound=>nil}
    end
    let(:released_cs_affiliations) do
      {:statusCode=>200,
        :feed=>
          {'student'=>
            {'affiliations'=>
              [{'type'=>
                {'code'=>'ADMT_UX',
                  'description'=>'Admitted Students CalCentral Access'},
                'status'=> {
                  'code'=>'ACT',
                  'description'=>'Active'},
                'fromDate'=>'2016-01-11'},
                {'type'=>{'code'=>'APPLICANT', 'description'=>'Applicant'},
                  'status'=> {
                    'code'=>'ACT',
                    'description'=>'Active'},
                  'fromDate'=>'2016-01-06'}]}},
        :studentNotFound=>nil}
    end
    before do
      allow(CampusOracle::Queries).to receive(:get_basic_people_attributes).with([auth_uid]).and_return([calnet_row])
      allow(HubEdos::Affiliations).to receive(:new).with(user_id: auth_uid).and_return(double(get: cs_affiliations))
    end
    subject { User::AuthenticationValidator.new(auth_uid).held_applicant? }
    context 'CalNet affiliations but no CS affiliations' do
      let(:calnet_row) do
        { 'affiliations' => 'EMPLOYEE-TYPE-STAFF,STUDENT-STATUS-EXPIRED'}
      end
      let(:cs_affiliations) { held_cs_affiliations }
      it {should be_falsey}
    end
    context 'CalNet affiliations and only pending-admit CS affiliation' do
      let(:calnet_row) do
        { 'affiliations' => 'EMPLOYEE-TYPE-STAFF,STUDENT-STATUS-EXPIRED'}
      end
      let(:cs_affiliations) { nil }
      it {should be_falsey}
    end
    context 'No CalNet affiliations and only pending-admit CS affiliation' do
      let(:calnet_row) { nil_calnet_row }
      let(:cs_affiliations) { held_cs_affiliations }
      it {should be_truthy}
    end
    context 'Only not-registered CalNet affiliation and only pending-admit CS affiliation' do
      let(:calnet_row) do
        { 'affiliations' => 'STUDENT-TYPE-NOT-REGISTERED'}
      end
      let(:cs_affiliations) { held_cs_affiliations }
      it {should be_truthy}
    end
    context 'No CalNet affiliations and released-admit CS affiliation' do
      let(:calnet_row) { nil_calnet_row }
      let(:cs_affiliations) { released_cs_affiliations }
      it {should be_falsey}
    end
    context 'No CalNet affiliations and multiple CS affiliations' do
      let(:calnet_row) { nil_calnet_row }
      let(:cs_affiliations) do
        {:statusCode=>200,
          :feed=>
            {"student"=>
              {"affiliations"=>
                [{"type"=>{"code"=>"STUDENT", "description"=>""},
                  'status'=> {
                    'code'=>'ACT',
                    'description'=>'Active'},
                  "fromDate"=>"2015-12-14"},
                  {"type"=>{"code"=>"UNDERGRAD", "description"=>"Undergraduate Student"},
                    'status'=> {
                      'code'=>'INA',
                      'description'=>'Inactive'},
                    "fromDate"=>"2015-12-14"}]}},
          :studentNotFound=>nil}
      end
      it {should be_falsey}
    end
    context 'Reverted released-admit' do
      let(:calnet_row) { nil_calnet_row }
      let(:cs_affiliations) do
        {:statusCode=>200,
          :feed=>
            {'student'=>
              {'affiliations'=>
                [{'type'=>
                  {'code'=>'ADMT_UX',
                    'description'=>'Admitted Students CalCentral Access'},
                  'status'=> {
                    'code'=>'INA',
                    'description'=>'Inactive'},
                  'fromDate'=>'2016-01-11'},
                  {'type'=>{'code'=>'APPLICANT', 'description'=>'Applicant'},
                    'status'=> {
                      'code'=>'ACT',
                      'description'=>'Active'},
                    'fromDate'=>'2016-01-06'}]}},
          :studentNotFound=>nil}
      end
      it {should be_truthy}
    end
  end

  describe '#validated_user_id' do
    before do
      allow_any_instance_of(User::AuthenticationValidator).to receive(:held_applicant?).and_return(is_held)
    end
    subject { User::AuthenticationValidator.new(auth_uid) }
    context 'user is only known as a held applicant' do
      let(:is_held) { true }
      it 'does not accept the session user_id' do
        expect(subject.validated_user_id).to be_nil
      end
    end
    context 'user is an old friend' do
      let(:is_held) { false }
      it 'allows the session user_id' do
        expect(subject.validated_user_id).to eq auth_uid
      end
    end
  end

  context 'feature disabled' do
    let(:feature_flag) { false }
    it 'should not waste time checking affiliations' do
      expect(CampusOracle::Queries).to receive(:get_basic_people_attributes).never
      expect(HubEdos::Affiliations).to receive(:new).never
      expect(User::AuthenticationValidator.new(auth_uid).validated_user_id).to eq auth_uid
    end
  end

  describe 'caching' do
    let(:cache_key) { User::AuthenticationValidator.cache_key(auth_uid) }
    before do
      allow_any_instance_of(User::AuthenticationValidator).to receive(:held_applicant?).and_return(is_held)
      allow(Settings.cache.expiration).to receive(:marshal_dump).and_return({
        'User::AuthenticationValidator'.to_sym => 8.hours,
        'User::AuthenticationValidator::short'.to_sym => 1.second
      })
    end
    subject { User::AuthenticationValidator.new(auth_uid) }
    context 'in a stable institutional relationship' do
      let(:is_held) { false }
      it 'remembers the good times' do
        expect(Rails.cache).to receive(:read).once.with(cache_key).and_call_original
        expect(Rails.cache).to receive(:write).once.with(
          cache_key,
          anything,
          {
            expires_in: 8.hours,
            force: true
          }
        )
        subject.validated_user_id
      end
    end
    context 'just met' do
      let(:is_held) { true }
      it 'hopes to make a friend' do
        expect(Rails.cache).to receive(:read).once.with(cache_key).and_call_original
        expect(Rails.cache).to receive(:write).once.with(
          cache_key,
          anything,
          {
            expires_in: 1.second,
            force: true
          }
        )
        subject.validated_user_id
      end
    end
  end

end
