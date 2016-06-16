describe Rosters::Common do

  let(:teacher_login_id) { rand(99999).to_s }
  let(:course_id) { rand(99999) }
  let(:section_id_one) { rand(99999).to_s }
  let(:section_id_two) { rand(99999).to_s }
  let(:section_id_three) { rand(99999).to_s }
  let(:fake_feed) do
    {
      :sections => [
        {:ccn => section_id_one, :name => 'COMPSCI 9G SLF 001'},
        {:ccn => section_id_two, :name => 'COMPSCI 9G SLF 002'},
        {:ccn => section_id_three, :name => 'COMPSCI 9G SLF 003'},
      ],
      :students => [
        {
          :enroll_status => 'E',
          :id => '9016',
          :login_id => '789124',
          :student_id => '289017',
          :first_name => 'Jack',
          :last_name => 'Nicholson',
          :email => 'jnicholson@example.com',
          :sections => [
            {:ccn => section_id_one, :name => 'COMPSCI 9G SLF 001'}
          ],
          :photo => '/canvas/1/photo/9016',
          :profile_url => 'http://example.com/courses/733/users/9016',
          :units => '4.0',
          :waitlist_position => nil
        },
        {
          :enroll_status => 'W',
          :id => '9017',
          :login_id => '789125',
          :student_id => '289018',
          :first_name => 'Seth',
          :last_name => 'Rogen',
          :email => 'srogen@example.com',
          :sections => [
            {:ccn => section_id_one, :name => 'COMPSCI 9G SLF 001'},
            {:ccn => section_id_two, :name => 'COMPSCI 9G SLF 002'}
          ],
          :photo => '/canvas/1/photo/9017',
          :profile_url => 'http://example.com/courses/733/users/9017',
          :units => '3.0',
          :waitlist_position => 2
        },
        {
          :enroll_status => 'C',
          :id => '9018',
          :login_id => '789164',
          :student_id => '289019',
          :first_name => 'Michael',
          :last_name => 'Fox',
          :email => 'mfox@example.com',
          :sections => [
            {:ccn => section_id_three, :name => 'COMPSCI 9G SLF 003'}
          ],
          :photo => '/canvas/1/photo/9018',
          :profile_url => 'http://example.com/courses/733/users/9018',
          :units => '3.0',
          :waitlist_position => nil
        },
      ]
    }
  end
  subject { Rosters::Common.new(teacher_login_id, course_id: course_id) }

  context 'when serving roster feed based content' do
    before { allow_any_instance_of(Rosters::Common).to receive(:get_feed_internal).and_return(fake_feed) }

    describe '#get_csv' do
      it "returns rosters csv" do
        rosters_csv_string = subject.get_csv
        expect(rosters_csv_string).to be_an_instance_of String
        rosters_csv = CSV.parse(rosters_csv_string, {headers: true})
        expect(rosters_csv.count).to eq 3

        expect(rosters_csv[0]).to be_an_instance_of CSV::Row
        expect(rosters_csv[0]['Name']).to eq 'Nicholson, Jack'
        expect(rosters_csv[0]['User ID']).to eq '789124'
        expect(rosters_csv[0]['Student ID']).to eq '289017'
        expect(rosters_csv[0]['Email Address']).to eq 'jnicholson@example.com'
        expect(rosters_csv[0]['Role']).to eq 'Student'
        expect(rosters_csv[0]['Sections']).to eq 'COMPSCI 9G SLF 001'

        expect(rosters_csv[1]).to be_an_instance_of CSV::Row
        expect(rosters_csv[1]['Name']).to eq 'Rogen, Seth'
        expect(rosters_csv[1]['User ID']).to eq '789125'
        expect(rosters_csv[1]['Student ID']).to eq '289018'
        expect(rosters_csv[1]['Email Address']).to eq 'srogen@example.com'
        expect(rosters_csv[1]['Role']).to eq 'Waitlist Student'
        expect(rosters_csv[1]['Sections']).to eq 'COMPSCI 9G SLF 001, COMPSCI 9G SLF 002'

        expect(rosters_csv[2]).to be_an_instance_of CSV::Row
        expect(rosters_csv[2]['Name']).to eq 'Fox, Michael'
        expect(rosters_csv[2]['User ID']).to eq '789164'
        expect(rosters_csv[2]['Student ID']).to eq '289019'
        expect(rosters_csv[2]['Email Address']).to eq 'mfox@example.com'
        expect(rosters_csv[2]['Role']).to eq 'Concurrent Student'
        expect(rosters_csv[2]['Sections']).to eq 'COMPSCI 9G SLF 003'
      end
    end
  end

  describe '#index_by_attribute' do
    it 'returns hash of arrays indexed by item attributes' do
      sections = [
        {:ccn => 123, :name => 'Course with CCN 123'},
        {:ccn => 124, :name => 'Course with CCN 124'},
        {:ccn => 125, :name => 'Course with CCN 125'},
      ]
      result = subject.index_by_attribute(sections, :ccn)
      expect(result).to be_an_instance_of Hash
      expect(result.keys).to eq [123, 124, 125]
      expect(result[123]).to eq sections[0]
      expect(result[124]).to eq sections[1]
      expect(result[125]).to eq sections[2]
    end
  end

  describe '#sections_to_name_string' do
    it 'returns section names in string format' do
      sections = [
        {:ccn => 123, :name => 'Course with CCN 123'},
        {:ccn => 124, :name => 'Course with CCN 124'},
      ]
      result = subject.sections_to_name_string([sections[0]])
      expect(result).to eq "Course with CCN 123"
      result = subject.sections_to_name_string([sections[1]])
      expect(result).to eq "Course with CCN 124"
      result = subject.sections_to_name_string(sections)
      expect(result).to eq "Course with CCN 123, Course with CCN 124"
    end
  end

  describe '#get_enrollments' do
    context 'when term is legacy sis' do
      let(:legacy_enrollments) {
        [
          {
            'ldap_uid' => '111111',
            'enroll_status' => 'E',
            'pnp_flag' => 'N',
            'first_name' => 'JIM',
            'last_name' => 'HALPERT',
            'student_email_address' => 'jhalpert@berkeley.edu',
            'student_id' => '22200999',
            'affiliations' => 'STUDENT-TYPE-REGISTERED'
          },
          {
            'ldap_uid' => '222222',
            'enroll_status' => 'W',
            'pnp_flag' => 'N',
            'first_name' => 'DWIGHT',
            'last_name' => 'SCHRUTE',
            'student_email_address' => 'dschrute@berkeley.edu',
            'student_id' => '22200777',
            'affiliations' => 'STUDENT-TYPE-REGISTERED'
          }
        ]
      }
      before do
        allow(Berkeley::Terms).to receive(:legacy?).and_return(true)
        allow(CampusOracle::Queries).to receive(:get_enrolled_students).and_return(legacy_enrollments)
      end
      it 'returns student basic attributes and enrollment status' do
        enrollments = subject.get_enrollments(course_id, '2016', 'D')
        expect(enrollments.count).to eq 2
        expect(enrollments[1][:ldap_uid]).to eq '222222'
        expect(enrollments[1][:student_id]).to eq '22200777'
        expect(enrollments[1][:first_name]).to eq 'DWIGHT'
        expect(enrollments[1][:last_name]).to eq 'SCHRUTE'
        expect(enrollments[1][:email]).to eq 'dschrute@berkeley.edu'
        expect(enrollments[1][:enroll_status]).to eq 'W'
      end
    end
    context 'when term is campus solutions' do
      let(:cs_enrollments) {
        [
          {
            'ldap_uid' => '333333',
            'student_id' => '22200666',
            'enroll_status' => 'E',
            'waitlist_position' => nil,
            'units' => 4,
            'grading_basis' => 'GRD',
            'major' => 'Cognitive Science BA',
            'terms_in_attendance_group' => 'R2TA'
          },
          {
            'ldap_uid' => '333333',
            'student_id' => '22200666',
            'enroll_status' => 'E',
            'waitlist_position' => nil,
            'units' => 4,
            'grading_basis' => 'GRD',
            'major' => 'Computer Science BA',
            'terms_in_attendance_group' => 'R2TA'
          },
          {
            'ldap_uid' => '444444',
            'student_id' => '22200555',
            'enroll_status' => 'E',
            'waitlist_position' => nil,
            'units' => 4,
            'grading_basis' => 'PNP',
            'major' => 'Computer Science BA',
            'terms_in_attendance_group' => nil
          },
          {
            'ldap_uid' => '555555',
            'student_id' => '22200444',
            'enroll_status' => 'W',
            'waitlist_position' => '25',
            'units' => 4,
            'grading_basis' => 'GRD',
            'major' => 'Nose Picking BA',
            'terms_in_attendance_group' => 'R8TA'
          }
        ]
      }
      let(:user_attributes) {
        [
          {:ldap_uid => '333333', :email_address => 'pambeesly@berkeley.edu'},
          {:ldap_uid => '444444', :email_address => 'kellykapoor@berkeley.edu'},
          {:ldap_uid => '555555', :email_address => 'kevinmalone@berkeley.edu'},
        ]
      }
      let(:enrollments) { subject.get_enrollments(course_id, '2016', 'D') }
      before do
        allow(Berkeley::Terms).to receive(:legacy?).and_return(false)
        allow(EdoOracle::Queries).to receive(:get_rosters).and_return(cs_enrollments)
        expect(User::BasicAttributes).to receive(:attributes_for_uids).with(["333333", "444444", "555555"]).and_return(user_attributes)
      end
      it 'returns student basic attributes and enrollment status' do
        expect(enrollments[0][:email]).to eq 'pambeesly@berkeley.edu'
        expect(enrollments[0][:enroll_status]).to eq 'E'
        expect(enrollments[0][:units]).to eq '4'
        expect(enrollments[1][:email]).to eq 'kellykapoor@berkeley.edu'
        expect(enrollments[1][:enroll_status]).to eq 'E'
        expect(enrollments[1][:units]).to eq '4'
        expect(enrollments[2][:email]).to eq 'kevinmalone@berkeley.edu'
        expect(enrollments[2][:enroll_status]).to eq 'W'
        expect(enrollments[2][:units]).to eq '4'
      end

      it 'converts grade option to string version' do
        expect(enrollments[0][:grade_option]).to eq 'Letter'
        expect(enrollments[1][:grade_option]).to eq 'P/NP'
        expect(enrollments[2][:grade_option]).to eq 'Letter'
      end

      it 'converts waitlist position to integer when present' do
        expect(enrollments[0][:waitlist_position]).to eq nil
        expect(enrollments[1][:waitlist_position]).to eq nil
        expect(enrollments[2][:waitlist_position]).to eq 25
      end

      it 'merges majors into single enrollment for student' do
        expect(enrollments[0][:majors]).to eq ['Cognitive Science BA', 'Computer Science BA']
        expect(enrollments[1][:majors]).to eq ['Computer Science BA']
        expect(enrollments[2][:majors]).to eq ['Nose Picking BA']
      end

      it 'converts and includes undergrad terms in attendance count' do
        expect(enrollments[0][:terms_in_attendance]).to eq '2'
        expect(enrollments[1][:terms_in_attendance]).to eq nil
        expect(enrollments[2][:terms_in_attendance]).to eq '8'
      end
    end
  end

end
