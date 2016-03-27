describe MyActivitiesController do

  before(:each) do
    @user_id = rand(99999).to_s
  end

  it "should be an empty activities feed on non-authenticated user" do
    get :get_feed
    assert_response :success
    json_response = JSON.parse(response.body)
    json_response.should == {}
  end

  it "should be an non-empty activities feed on authenticated user" do
    session['user_id'] = @user_id
    dummy = JSON.parse(File.read(Rails.root.join('public/dummy/json/activities.json')))
    MyActivities::Merged.any_instance.stub(:get_feed).and_return(dummy)
    get :get_feed
    json_response = JSON.parse(response.body)
    json_response.should_not == {}
    json_response["activities"].instance_of?(Array).should == true
  end

  it "should return a valid activities feed for an authenticated user" do
    session['user_id'] = @user_id
    dummy = JSON.parse(File.read(Rails.root.join('public/dummy/json/activities.json')))
    MyActivities::Merged.any_instance.stub(:get_feed).and_return(dummy)
    get :get_feed
    json_response = JSON.parse(response.body)
    json_response["activities"].instance_of?(Array).should == true
    json_response["activities"].each do | activity |
      %w(type source emitter).each do | req_field |
        activity[req_field].blank?.should_not == true
      end
    end
  end

  context 'delegated access' do
    let(:uid) {random_id}
    let(:campus_solutions_id) {random_id}
    include_context 'delegated access'
    context 'enrollments-only access' do
      let(:privileges) do
        {
          viewEnrollments: true
        }
      end
      it 'denies all access' do
        get :get_feed
        expect(response.status).to eq 403
        expect(response.body).to eq ' '
      end
    end
    context 'financial access' do
      let(:privileges) do
        {
          financial: true
        }
      end
      it 'allows access only to Financial Aid tasks' do
        get :get_feed
        assert_response :success
        json_response = JSON.parse(response.body)
        json_response.should be_present
        cs_finaid_activities = json_response['activities'].select {|t| (t['emitter'] == 'Campus Solutions') && t['cs']['isFinaid']}
        expect(cs_finaid_activities).to be_present
        expect(json_response['activities']).to eq cs_finaid_activities
      end
    end
  end

end
