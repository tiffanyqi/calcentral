describe MyClassesController do

  before(:each) do
    @user_id = rand(99999).to_s
  end

  it "should be an empty course sites feed on non-authenticated user" do
    get :get_feed
    assert_response :success
    json_response = JSON.parse(response.body)
    json_response.should == {}
  end

  it "should be an non-empty course feed on authenticated user" do
    MyClasses::Merged.any_instance.stub(:get_feed).and_return(
      [{course_code: "PLEO 22",
      id: "750027",
      emitter: Canvas::Proxy::APP_NAME}])
    session['user_id'] = @user_id
    get :get_feed
    json_response = JSON.parse(response.body)
    json_response.size.should == 1
    json_response[0]["course_code"].should == "PLEO 22"
  end

  let(:make_request) { get :get_feed }
  it_should_behave_like 'a user authenticated api endpoint'
  it_behaves_like 'an unauthorized endpoint for delegates'

end
