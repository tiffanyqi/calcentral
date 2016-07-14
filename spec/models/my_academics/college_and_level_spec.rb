describe 'MyAcademics::CollegeAndLevel' do

  let(:uid) { '61889' }
  let(:eight_digit_cs_id) { '87654321' }
  let(:ten_digit_cs_id) { '1234567890' }

  let(:feed) do
    {}.tap { |feed| MyAcademics::CollegeAndLevel.new(uid).merge feed }
  end

  context 'when legacy user but non-legacy term' do
    let(:status_proxy) { HubEdos::AcademicStatus.new(user_id: uid, fake: true) }
    before do
      allow_any_instance_of(CalnetCrosswalk::ByUid).to receive(:lookup_campus_solutions_id).and_return eight_digit_cs_id
      allow(Settings.terms).to receive(:fake_now).and_return('2016-10-01'.to_datetime)
      allow(Settings.features).to receive(:cs_academic_profile_prefers_legacy).and_return(prefer_legacy)
    end
    context 'CS-based registration data not fully baked' do
      let(:prefer_legacy) {true}
      let(:bearfacts_proxy) { Bearfacts::Profile.new(user_id: uid, fake: true) }
      it 'sources from Bear Facts' do
        expect(Bearfacts::Profile).to receive(:new).and_return bearfacts_proxy
        expect(HubEdos::AcademicStatus).to receive(:new).and_return status_proxy
        expect(feed[:collegeAndLevel][:level]).to eq 'Senior'
      end
    end
    context 'CS registration data is ready to go' do
      let(:prefer_legacy) {false}
      it 'sources from Hub' do
        expect(Bearfacts::Profile).to receive(:new).never
        expect(HubEdos::AcademicStatus).to receive(:new).and_return status_proxy
        expect(feed[:collegeAndLevel][:statusCode]).to eq 200
      end
    end
  end

  context 'when sourced from Hub academic status' do
    let(:status_proxy) { HubEdos::AcademicStatus.new(user_id: uid, fake: true) }
    before do
      allow_any_instance_of(CalnetCrosswalk::ByUid).to receive(:lookup_campus_solutions_id).and_return ten_digit_cs_id
      allow(HubEdos::AcademicStatus).to receive(:new).and_return status_proxy
    end

    it 'reports success' do
      expect(feed[:collegeAndLevel][:statusCode]).to eq 200
    end

    it 'translates careers' do
      expect(feed[:collegeAndLevel][:careers]).to eq ['Undergraduate']
    end

    it 'translates level' do
      expect(feed[:collegeAndLevel][:level]).to eq 'Junior'
    end

    it 'translates terms in attendance' do
      expect(feed[:collegeAndLevel][:termsInAttendance]).to eq '4'
    end

    it 'translates majors' do
      expect(feed[:collegeAndLevel][:majors].first).to eq({
        college: 'Undergrad Letters & Science',
        major: 'English BA'
      })
    end

    it 'translates minors' do
      expect(feed[:collegeAndLevel][:minors].first).to eq({
        college: 'Undergrad Letters & Science',
        minor: 'Art BA'
      })
    end

    it 'translates plans' do
      expect(feed[:collegeAndLevel][:plans]).to eq(
        [
          {
            :code => "25345U",
            :primary => true
          },
          {
            :code => "25090U",
            :primary => false
          },
        ]
      )
    end

    it 'specifies cpp roles' do
      expect(feed[:collegeAndLevel][:roles]).to eq({
        fpf: false
      })
    end

    context 'fpf plan is present' do
      it 'includes fpf role' do
        expect(feed[:collegeAndLevel][:roles]).to eq({
          fpf: false
        })
      end
    end

    it 'specifies term name' do
      expect(feed[:collegeAndLevel][:termName]).to eq 'Spring 2017'
    end

    it 'includes transfer credit as cumulativeUnits' do
      expect(feed[:collegeAndLevel][:cumulativeUnits]).to be
    end

    context 'empty status feed' do
      before { status_proxy.set_response(status: 200, body: '{}') }
      it 'reports empty' do
        expect(feed[:collegeAndLevel][:empty]).to eq true
      end
    end

    context 'errored status feed' do
      before { status_proxy.set_response(status: 502, body: '') }
      it 'reports error' do
        expect(feed[:collegeAndLevel][:errored]).to eq true
      end
    end

    context 'status feed lacking some data' do
      before do
        status_proxy.override_json do |json|
          json['apiResponse']['response']['any']['students'][0]['academicStatuses'][0].delete 'currentRegistration'
        end
      end
      it 'returns what data it can' do
        expect(feed[:collegeAndLevel][:careers]).to be_present
        expect(feed[:collegeAndLevel][:majors]).to be_present
        expect(feed[:collegeAndLevel][:level]).to be nil
        expect(feed[:collegeAndLevel][:termName]).to be nil
      end
    end
  end

  context 'when legacy user and in legacy term with no Hub status' do
    before do
      allow_any_instance_of(CalnetCrosswalk::ByUid).to receive(:lookup_campus_solutions_id).and_return eight_digit_cs_id
      allow(Berkeley::Terms).to receive(:legacy?).and_return(true)
      allow_any_instance_of(HubEdos::AcademicStatus).to receive(:get).and_return({})
    end

    context 'known test users' do
      before do
        profile_proxy = Bearfacts::Profile.new(user_id: uid, fake: true)
        allow(Bearfacts::Profile).to receive(:new).and_return profile_proxy
        expect(feed).not_to be_empty
      end

      let(:majors) { feed[:collegeAndLevel][:majors] }

      it 'should get properly formatted data from fake Bearfacts' do
        expect(majors).to have(1).items
        expect(majors.first).to include(
          college: 'College of Letters & Science',
          major: 'Statistics'
        )
        expect(feed[:collegeAndLevel]).to include(
          careers: [
            'Undergraduate'
          ],
          termName: 'Fall 2015'
        )
      end

      context 'enrollment in multiple colleges' do
        let(:uid) { '300940' }
        it 'should return multiple colleges and majors' do
          expect(majors).to have(2).items
          expect(majors[0]).to include(
            college: 'College of Natural Resources',
            major: 'Conservation And Resource Studies'
          )
          expect(majors[1]).to include(
            college: 'College of Environmental Design',
            major: 'Landscape Architecture'
          )
        end
      end

      context 'a concurrent enrollment triple major' do
        let(:uid) { '212379' }
        it 'should return even more colleges and majors' do
          expect(majors).to have(3).items
          expect(majors[0]).to include(
            college: 'College of Chemistry',
            major: 'Chemistry'
          )
          expect(majors[1]).to include(
            college: 'College of Letters & Science',
            major: 'Applied Mathematics'
          )
          expect(majors[2]).to include(
            college: '',
            major: 'Physics'
          )
        end
      end

      context 'a double law major' do
        let(:uid) { '212381' }
        it 'should return the law in all its aspects' do
          expect(majors).to have(2).items
          expect(majors[0]).to include(
            college: 'School of Law',
            major: 'Jurisprudence And Social Policy'
          )
          expect(majors[1]).to include(
            college: '',
            major: 'Law'
          )
        end
      end
    end

    context 'failing bearfacts proxy' do
      let(:uid) {'212381'}
      let(:feed) {{}}
      before(:each) do
        stub_request(:any, /#{Regexp.quote(Settings.bearfacts_proxy.base_url)}.*/).to_raise(Errno::EHOSTUNREACH)
        Bearfacts::Profile.new({user_id: uid, fake: false})
      end
      it 'indicates a server failure' do
        MyAcademics::CollegeAndLevel.new(uid).merge(feed)
        expect(feed[:collegeAndLevel][:errored]).to be_truthy
      end
    end

    context 'when Bearfacts feed is incomplete' do
      let(:uid) {rand(999999)}
      let(:feed) {{}}
      before do
        allow(Bearfacts::Profile).to receive(:new).with(user_id: uid).and_return(double(get: {
          feed: FeedWrapper.new(MultiXml.parse(xml_body))
        }))
        MyAcademics::CollegeAndLevel.new(uid).merge(feed)
      end

      context 'when Bearfacts student profile lacks key data' do
        let(:xml_body) {
          '<studentProfile xmlns="urn:berkeley.edu/babl" termName="Spring" termYear="2014" asOfDate="May 27, 2014 12:00 AM"><studentType>STUDENT</studentType><noProfileDataFlag>false</noProfileDataFlag><studentGeneralProfile><studentName><firstName>OWPRQTOPEW</firstName><lastName>SEBIRTFEIWB</lastName></studentName></studentGeneralProfile></studentProfile>'
        }
        it 'reports an empty feed for the CalCentral current term' do
          expect(feed[:collegeAndLevel]).to include(
            empty: true,
            termName: Berkeley::Terms.fetch.current.to_english
          )
          expect(feed[:collegeAndLevel]).not_to include :errored
        end
      end

      context 'when Bearfacts student profile is completely empty' do
        let(:xml_body) { nil }
        it 'reports an empty feed for the CalCentral current term' do
          expect(feed[:collegeAndLevel]).to include(
            empty: true,
            termName: Berkeley::Terms.fetch.current.to_english
          )
          expect(feed[:collegeAndLevel]).not_to include :errored
        end
      end
    end
  end

  describe '#profile_in_past?' do
    subject { MyAcademics::CollegeAndLevel.new(uid).profile_in_past? profile }
    let(:profile) { {termName: term_name} }
    context 'profile is for the current CalCentral  term' do
      let(:term_name) { Berkeley::Terms.fetch.current.to_english }
      it {should eq false}
    end
    context 'profile is for the next CalCentral term' do
      let(:term_name) { Berkeley::Terms.fetch.next.to_english }
      it {should eq false}
    end
    context 'profile is for the previous CalCentral term' do
      let(:term_name) { Berkeley::Terms.fetch.previous.to_english }
      it {should eq true}
    end
    context 'profile is empty' do
      let(:profile) { {empty: true} }
      it {should eq false}
    end
  end

end
