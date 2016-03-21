describe MyGroupsController do

  before(:each) do
    @user_id = rand(99999).to_s
  end

  it "should be an empty course sites feed on non-authenticated user" do
    get :get_feed
    assert_response :success
    json_response = JSON.parse(response.body)
    json_response.should == {}
  end

  it "should check for valid fields on the my groups feed" do
    #needs to be updated afterwards
    session['user_id'] = @user_id
    get :get_feed
    json_response = JSON.parse(response.body)
    json_response["groups"].is_a?(Array).should == true
    json_response["groups"].each do |group_entry|
      group_entry["id"].blank?.should_not == true
      group_entry["site_url"].blank?.should_not == true
      (group_entry["emitter"] =~ (/(bcourses|callink)$/i)).should_not be_nil
    end
  end

  let(:make_request) { get :get_feed }
  it_should_behave_like 'a user authenticated api endpoint'
  it_behaves_like 'an unauthorized endpoint for delegates'

end
