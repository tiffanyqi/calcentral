describe "MyAcademics::Requirements" do

  it "should get properly formatted data from fake Bearfacts" do
    oski_profile_proxy = Bearfacts::Profile.new({:user_id => "61889", :fake => true})
    Bearfacts::Profile.stub(:new).and_return(oski_profile_proxy)

    feed = {}
    MyAcademics::Requirements.new("61889").merge(feed)
    feed.empty?.should be_falsey

    oski_requirements = feed[:requirements]
    oski_requirements.length.should == 4
  end

  context "failing bearfacts proxy" do
    before(:each) do
      stub_request(:any, /#{Regexp.quote(Settings.bearfacts_proxy.base_url)}.*/).to_raise(Errno::EHOSTUNREACH)
      Bearfacts::Profile.new({:user_id => "61889", :fake => false})
    end

    subject do
      MyAcademics::Requirements.new("61889").merge(@feed = {})
      @feed
    end

    it { should be_blank }
  end

  context 'non-legacy ID' do
    before { allow_any_instance_of(CalnetCrosswalk::ByUid).to receive(:lookup_campus_solutions_id).and_return '1234567890' }
    it 'should not attempt merge' do
      expect(Bearfacts::Profile).not_to receive :new
      feed = {}.tap { |feed| MyAcademics::Requirements.new('61889').merge feed }
      expect(feed).to be_empty
    end
  end
end
