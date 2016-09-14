describe MyAcademics::Exams do

  let(:uid) {rand(99999).to_s}
  before do
    allow(Settings.terms).to receive(:fake_now).and_return '2016-04-01'
  end

  ## TEST CLASSES

  # a class with recurring times
  let(:ug_class_recurring) do
    {
      :role => 'Student',
      :course_code => 'BIO ENG 131',
      :courseCatalog => '131',
      :sections => [
        {
          :is_primary_section => true,
          :schedules => {
            :recurring => [
              {:buildingName=>'LeConte',:roomNumber=>'251',:schedule=>'MWF 2:00P-2:59P'}
            ]
          }
        },
        {
          :is_primary_section => false,
          :schedules => {
            :recurring=>[
              {:buildingName=>'Etcheverry',:roomNumber=>'1111',:schedule=>'W 4:00P-5:29P'}
            ]
          }
        }
      ]
    }
  end

  # chem 3b course exception
  let(:chem_3b_ug_class) do
    {
      :role=>'Student',
      :course_code=>'CHEM 3B',
      :courseCatalog=>'3B',
      :sections=> [
        {
          :is_primary_section=>true,
          :schedules=> {
            :recurring=>[
              {:buildingName=>'Pimentel',:roomNumber=>'1',:schedule=>'MWF 2:00P-2:59P'}
            ]
          }
        }
      ]
    }
  end

  # a class with a waitlist and recurring
  let(:waitlist_recurring_ug_class) do
    {
      :role=>'Student',
      :course_code=>'COMPSCI 61B',
      :courseCatalog=>'61B',
      :sections=> [
        {
          :is_primary_section=>true,
          :schedules=>
            {
              :recurring=>[
                {:buildingName=>'Dwinelle',:roomNumber=>'155',:schedule=>'MWF 3:00P-3:59P'}
              ]
            },
          :waitlisted => true
        }
      ]
    }
  end

  # an ug class with nothing
  let(:no_recurring_ug_class) do
    {
      :role=>'Student',
      :course_code=>'EWMBA 107',
      :courseCatalog=>'107',
      :sections=>[
        {
          :is_primary_section=>true,
          :schedules=>
            {
              :recurring=>[]
            }
        }
      ]
    }
  end

  # a grad class with nothing
  let(:no_recurring_grad_class) do
    {
      :role=>'Student',
      :course_code=>'EWMBA 299',
      :courseCatalog=>'299',
      :sections=>[
        {
          :is_primary_section=>true,
          :schedules=>
            {
              :recurring=>[]
            }
        }
      ]
    }
  end

  # grad class and recurring
  let(:recurring_grad_class) do
    {
      :role=>'Student',
      :course_code=>'EWMBA 201B',
      :courseCatalog=>'201B',
      :sections=> [
        {
          :is_primary_section=>true,
          :schedules=>
            {
              :recurring=>[
                {:schedule=>'Sa 2:00P-6:00P'}
              ]
            }
        }
      ]
    }
  end

  # after parsed academic data, class with time
  let(:ug_class_time) do
    {:name => 'BIO ENG 131',:number => 131,:time => 'MWF 2:00P-2:59P',:waitlisted => nil}
  end

  # after parsed academic data, a course exception
  let(:ug_course_exception) do
    {:name => 'CHEM 3B',:number => 3,:time => 'MWF 2:00P-2:59P',:waitlisted => nil}
  end

  # after parsed academic data, a waitlisted class
  let(:waitlisted_class) do
    {:name => 'COMPSCI 61B',:number => 61,:time => 'MWF 3:00P-3:59P',:waitlisted => true}
  end

  # after parsed academic data, ug, nothing
  let(:ug_class_no_time) do
    {:name => 'EWMBA 107',:number => 107,:time => nil,:waitlisted => nil}
  end

  # after parsed academic data, grad, nothing
  let(:grad_class_no_time) do
    {:name => 'EWMBA 204',:number => 204,:time => nil,:waitlisted => nil}
  end

  # after parsed academic data, cs has exams
  let(:cs_class) do
    {
      :name => 'CHEM 3B',:number => 3,:time => 'MWF 2:00P-2:59P',:waitlisted => nil,
      :exam_location => 'Dwinelle 155',
      :exam_date => 'Mon 5/16',
      :exam_time => '8:00P',
      :exam_date_no_day => '5/16',
      :exam_slot => '16/May/2016 20:00:00'.to_datetime
    }
  end

  ## TEST CLUSTERS

  let(:fall_2016_classes) do
    [
      ug_class_recurring,
      chem_3b_ug_class,
      waitlist_recurring_ug_class,
      no_recurring_ug_class,
      no_recurring_grad_class
    ]
  end

  let(:fall_2016_semester) do
    {
      :name=>'Fall 2016',:termCode=>'D',:termYear=>'2016',:timeBucket=>'future',:slug=>'fall-2016',
      :classes=> fall_2016_classes
    }
  end

  let(:summer_2016_semester) do
    {:name=>'Summer 2016',:termCode=>'C',:timeBucket=>'future'}
  end

  let(:fall_2015_semester) do
    {:name=>'Fall 2015',:termCode=>'D',:timeBucket=>'past'}
  end

  let(:spring_2016_semester) do
    {:name=>'Spring 2016',:termCode=>'B',:termYear=>'2016',:timeBucket=>'current',:slug=>'spring-2016',
     :classes=> [
        ug_class_recurring,
        chem_3b_ug_class,
        recurring_grad_class
      ]
    }
  end

  let(:fall_2016_exams_after_parsed) do
    {
      3 => [
        {
          :name => 'CHEM 3B',:number => 3,:time => 'MWF 2:00P-2:59P',:waitlisted => nil,
          :exam_location => '',:exam_date => 'Mon 12/12',:exam_time => '3-6P',:exam_slot => 3
        }
      ],
      8 => [
        {
          :name => 'COMPSCI 61B',:number => 61,:time => 'MWF 3:00P-3:59P',:waitlisted => true,
          :exam_location => '',:exam_date => 'Tue 12/13',:exam_time => '7-10P',:exam_slot => 8
        }
      ],
      15 => [
        {
          :name => 'BIO ENG 131',:number => 131,:time => 'MWF 2:00P-2:59P',:waitlisted => nil,
          :exam_location => '',:exam_date => 'Thu 12/15',:exam_time => '3-6P',:exam_slot => 15
        }
      ]
    }
  end

  let(:spring_2016_exams_after_parsed) do
    {
      '16/May/2016 20:00:00'.to_datetime => [
        {
          :name => 'CHEM 3B',:number => 3,:time => 'MWF 2:00P-2:59P',:waitlisted => nil,
          :exam_location => 'Dwinelle 155',
          :exam_date => 'Mon 5/16',
          :exam_time => '8:00P',
          :exam_date_no_day => '5/16',
          :exam_slot => '16/May/2016 20:00:00'.to_datetime
        }
      ],
    }
  end

  let(:fall_2016_semester_after_parsed) do
    {
      :cs_data_available => false,:name => 'Fall 2016',:term => 'D',
      :term_year => '2016',:timeBucket => 'future',:slug=>'fall-2016',
      :courses => [
        ug_class_time,
        ug_course_exception,
        waitlisted_class,
        ug_class_no_time,
        grad_class_no_time
      ]
    }
  end

  let(:spring_2016_semester_after_parsed) do
    {
      :cs_data_available => true,:name => 'Spring 2016',:term => 'B',
      :term_year => '2016',:timeBucket => 'current',:slug=>'spring-2016',
      :courses => [
        cs_class,
        # the following exams aren't directly a result of parse_academic_data
        ug_class_time,
        grad_class_no_time
      ]
    }
  end

  let(:semesters) do
    [
      fall_2016_semester,
      summer_2016_semester,
      fall_2015_semester,
      spring_2016_semester
    ]
  end

  let(:feed) do
    {
      :collegeAndLevel=>
        {
          :careers=>['Undergraduate'],
          :isCurrent=>true
        },
      :semesters=> semesters
    }
  end


  subject do
    MyAcademics::Exams.new(uid)
  end

  let(:final_exam_logic) do
    Berkeley::FinalExamSchedule.fetch
  end

  let(:feed_after_parse_academic_data) do
    [
      fall_2016_semester_after_parsed,
      spring_2016_semester_after_parsed
    ]
  end

  let(:merged_result) do
    subject.merge(feed)
  end


  ## TEST CASES

  context 'as a student' do
    context 'with no semesters' do
      let(:semesters) { [] }

      it 'should parse academic data correctly' do
        result = subject.parse_academic_data(feed[:semesters])
        expect(result.length).to eq 0
      end
    end

    context 'with semesters and classes' do
      it 'should parse academic data correctly' do
        result = subject.parse_academic_data(feed[:semesters])
        expect(result.length).to eq 2
        fall_2016 = result[0]
        spring_2016 = result[1]
        expect(fall_2016[:cs_data_available]).to eq false
        expect(spring_2016[:cs_data_available]).to eq false # will be true with real CS data

        fall_courses = result[0][:courses]
        spring_courses = result[1][:courses]

        expect(fall_courses.length).to eq 5
        fall_courses.each do |course|
          expect(course[:name]).to be
          expect(course[:number]).to be
        end

        expect(spring_courses.length).to eq 3
        spring_courses.each do |course|
          expect(course[:name]).to be
          expect(course[:number]).to be
        end
      end

      it 'should assign exams correctly' do
        result = subject.assign_exams(feed_after_parse_academic_data, final_exam_logic)
        expect(result.length).to eq 2

        spring_exams = result[0][:exams]
        fall_exams = result[1][:exams]

        expect(spring_exams.length).to eq 1
        spring_exams.each do |exam_group, data|
          data.each do |course|
            expect(course[:exam_slot]).to eq exam_group
            case exam_group
            when '16/May/2016 20:00:00'.to_datetime
              expect(course[:exam_date]).to eq 'Mon 5/16'
              expect(course[:exam_time]).to eq '8:00P'
            end
          end
        end

        expect(fall_exams.length).to eq 3
        spring_exams.each do |exam_group, data|
          data.each do |course|
            expect(course[:exam_slot]).to eq exam_group
            case exam_group
            when 3
              expect(course[:exam_date]).to eq 'Mon 12/12'
              expect(course[:exam_time]).to eq '3-6P'
            when 14
              expect(course[:exam_date]).to eq 'Thu 12/15'
              expect(course[:exam_time]).to eq '11:30-2:30P'
            end
          end
        end
      end
    end

    context 'with semesters and no classes' do
      let(:fall_2016_classes) { [] }

      it 'should parse academic data correctly' do
        result = subject.parse_academic_data(feed[:semesters])
        expect(result[0][:courses].length).to eq 0
        expect(result[1][:courses].length).to eq 3
      end
    end

    context 'with classes and no exams as cs data is populated' do
      let(:feed_after_parse_academic_data) do
        [{
          :cs_data_available => true,:name => 'Fall 2016',:term => 'D',:term_year => '2016',:timeBucket => 'future',
          :courses => [ug_class_time,ug_course_exception,waitlisted_class]
        }]
      end

      it 'should assign exams correctly' do
        result = subject.assign_exams(feed_after_parse_academic_data, final_exam_logic)
        expect(result[0][:exams].length).to eq 0
      end
    end

    it 'should not have any summer or past semesters' do
      merged_result.each do |semester|
        expect(semester[:term]).not_to eq('C')
        expect(semester[:timeBucket]).not_to eq('past')
      end
    end

    it 'should transition data correctly' do
      merged_result.each do |semester|
        semester[:exams].each do |exam_slot, data|
          expect(exam_slot).to be_kind_of(DateTime) if semester[:cs_data_available]
          expect(exam_slot).to be_kind_of(Integer) if !semester[:cs_data_available]
        end
      end
    end

    it 'should determine cs data is available correctly' do
      expect(subject.determine_cs_data_available(fall_2016_semester)).to eq false
      expect(subject.determine_cs_data_available(spring_2016_semester)).to eq false # will be true with real cs data
    end

    it 'should determine the exam key correctly' do
      expect(subject.determine_exam_key(fall_2016_semester_after_parsed, ug_class_time, final_exam_logic)).to eq 'D-M-2:00P'
      expect(subject.determine_exam_key(fall_2016_semester_after_parsed, ug_course_exception, final_exam_logic)).to eq 'D-CHEM 3B'
      expect(subject.determine_exam_key(fall_2016_semester_after_parsed, ug_class_no_time, final_exam_logic)).to eq nil
      expect(subject.determine_exam_key(spring_2016_semester_after_parsed, cs_class, final_exam_logic)).to eq 'B-CHEM 3B'
    end

    it 'should determine the exam date correctly' do
      expect(subject.determine_exam_date(fall_2016_semester_after_parsed, 'Monday')).to eq 'Mon 12/12'
      expect(subject.determine_exam_date(fall_2016_semester_after_parsed, 'Tuesday')).to eq 'Tue 12/13'
      expect(subject.determine_exam_date(spring_2016_semester_after_parsed, 'Monday')).to eq 'Mon 5/9'
    end

  end
end
