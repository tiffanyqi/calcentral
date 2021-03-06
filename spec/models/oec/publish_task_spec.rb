describe Oec::PublishTask do
  let(:term_code) { '2015-B' }
  let(:now) { DateTime.now }
  let(:task) do
    Oec::PublishTask.new(term_code: term_code, local_write: local_write, date_time: now, allow_past_term: true)
  end
  let(:tmp_publish_directory) { now.strftime "publish_#{Oec::Task.date_format}_%H%M%S" }

  include_context 'OEC enrollment data merge'
  include_context 'OEC instructor data import from previous terms'

  def read_exported_csv(filename)
    File.read task.staging_dir.join(tmp_publish_directory, "#{filename}.csv")
  end

  let(:instructors) { Oec::Instructors.from_csv(read_exported_csv 'instructors') }
  let(:courses) { Oec::Courses.from_csv(read_exported_csv 'courses') }
  let(:students) { Oec::Students.from_csv(read_exported_csv 'students') }
  let(:course_instructors) { Oec::CourseInstructors.from_csv(read_exported_csv 'course_instructors') }
  let(:course_students) { Oec::CourseStudents.from_csv(read_exported_csv 'course_students') }
  let(:supervisors) { Oec::Supervisors.from_csv(read_exported_csv 'supervisors') }
  let(:course_supervisors) { Oec::CourseSupervisors.from_csv(read_exported_csv 'course_supervisors') }

  before(:each) do
    allow(Oec::RemoteDrive).to receive(:new).and_return fake_remote_drive
    allow(fake_remote_drive).to receive(:find_nested).and_return mock_google_drive_item
    allow(fake_remote_drive).to receive(:export_csv)
                                  .and_return(merged_course_confirmations_csv, merged_supervisor_confirmations_csv)
    allow(Settings.terms).to receive(:fake_now).and_return DateTime.parse('2015-03-09 12:00:00')

    allow(Oec::Queries).to receive(:students_for_cntl_nums).and_return student_data_rows
    allow(Oec::Queries).to receive(:enrollments_for_cntl_nums).and_return(enrollment_data_rows, suffixed_enrollment_data_rows)
    allow_any_instance_of(Oec::Task).to receive(:default_term_dates).and_return({'START_DATE' => '01-26-2015', 'END_DATE' => '05-11-2015'})
  end

  describe 'exported sheet structure' do
    let(:local_write) { 'Y' }

    shared_examples 'data integrity checks' do
      it 'should create local staging directory' do
        path = "#{task.staging_dir.expand_path}/#{tmp_publish_directory}"
        expect(path).to start_with '/'
        expect(File).to exist path
      end

      it 'should produce a sane instructors sheet' do
        expect(instructors).to have_at_least(16).items
        ('a'..'p').map do |l|
          matches = instructors.select { |instructor| instructor['LAST_NAME'] == (l*4).capitalize }
          expect(matches).to have(1).item
          expect(matches[0]['FIRST_NAME']).to start_with l.capitalize
          expect(matches[0]['EMAIL_ADDRESS']).to eq "#{l*4}@berkeley.edu"
        end
      end

      it 'should produce a sane courses sheet including only courses marked for evaluation' do
        course_ids.each do |course_id|
          confirmation_rows = merged_course_confirmations.select { |row| row['COURSE_ID'] == course_id && row['EVALUATE'] == 'Y' }
          course_rows = courses.select { |course| course['COURSE_ID'] == course_id }
          if confirmation_rows.any?
            expect(course_rows).to have(1).item
            expect(course_rows[0]['COURSE_ID']).to eq course_rows[0]['COURSE_ID_2']
          else
            expect(course_rows).to be_empty
          end
        end
      end

      it 'should produce a sane course_instructors sheet' do
        course_instructors_to_validate = course_instructors.select { |ci| ci['COURSE_ID'].start_with? term_code }
        expect(course_instructors_to_validate).to_not be_empty
        course_instructors_to_validate.each do |course_instructor|
          expect(courses.find { |course| course['COURSE_ID'] == course_instructor['COURSE_ID'] }).to be_present
          expect(instructors.find { |instructor| instructor['LDAP_UID'] == course_instructor['LDAP_UID'] }).to be_present
        end
      end

      it 'should produce a sane students sheet' do
        expect(students.first).to_not be_empty
        students.each do |student|
          expect(course_students.find { |course_student| course_student['LDAP_UID'] == student['LDAP_UID'] }).to be_present
        end
      end

      it 'should produce a sane course_students sheet' do
        expect(course_students.first).to_not be_empty
        course_students.each do |course_student|
          expect(courses.find { |course| course['COURSE_ID'] == course_student['COURSE_ID'] }).to be_present
          expect(students.find { |student| student['LDAP_UID'] == course_student['LDAP_UID'] }).to be_present
        end
      end

      it 'should produce a sane course_supervisors sheet' do
        expect(course_supervisors.first).to_not be_empty
        course_supervisors.each do |course_supervisor|
          course = courses.find { |course| course['COURSE_ID'] == course_supervisor['COURSE_ID'] }
          supervisor = supervisors.find { |supervisor| supervisor['LDAP_UID'] == course_supervisor['LDAP_UID'] }
          expect(course['DEPT_FORM']).to eq course_supervisor['DEPT_NAME']
          expect([supervisor['DEPT_NAME_1'], supervisor['DEPT_NAME_2']]).to include(course_supervisor['DEPT_NAME'])
        end
      end

      it 'should export the same supervisors sheet it was given' do
        expect(read_exported_csv 'supervisors').to eq merged_supervisor_confirmations_csv
      end
    end

    context 'valid fixture data' do
      before { task.run }
      include_examples 'data integrity checks'
    end

    context 'merging instructor data from previous terms' do
      let(:previous_course_instructors_csv) do
        [
          Oec::CourseInstructors.new.headers.join(','),
          '2014-B-11111,55555',
          '2014-C-11111,66666',
          '2014-D-11111,77777',
          '2014-D-22222,128533'
        ].join("\n")
      end
      let(:previous_instructors_csv) do
        [
          Oec::Instructors.new.headers.join(','),
          '55555,UID:55555,Xerxes,Xxxx,xxxx@berkeley.edu,23',
          '66666,UID:66666,Ysidro,Yyyy,yyyy@berkeley.edu,23',
          '77777,UID:77777,Zaphod,Zzzz,zzzz@berkeley.edu,23',
          '128533,UID:88888,Ancient,Aaaa,ancient-email-address@compuserve.com,23'
        ].join("\n")
      end

      before { task.run }
      include_examples 'data integrity checks'

      it 'should include course-instructor pairings less than a year old' do
        expect(course_instructors.find { |ci| ci['COURSE_ID'] == '2014-C-11111' && ci['LDAP_UID'] == '66666'}).to be_present
        expect(course_instructors.find { |ci| ci['COURSE_ID'] == '2014-D-11111' && ci['LDAP_UID'] == '77777'}).to be_present
        expect(course_instructors.find { |ci| ci['COURSE_ID'] == '2014-D-22222' && ci['LDAP_UID'] == '128533'}).to be_present
        expect(instructors.find { |i| i['LDAP_UID'] == '66666'}).to be_present
        expect(instructors.find { |i| i['LDAP_UID'] == '77777'}).to be_present
      end

      it 'should not include course-instructor pairings a year old or more' do
        expect(course_instructors.find { |ci| ci['COURSE_ID'] == '2014-B-11111' && ci['LDAP_UID'] == '55555'}).not_to be_present
        expect(instructors.find { |i| i['LDAP_UID'] == '55555'}).not_to be_present
      end

      it 'should merge instructor data from previous terms when current-term data absent' do
        expect(instructors.find { |i| i['LDAP_UID'] == '66666'}).to include({'FIRST_NAME' => 'Ysidro', 'LAST_NAME' => 'Yyyy', 'EMAIL_ADDRESS' => 'yyyy@berkeley.edu'})
        expect(instructors.find { |i| i['LDAP_UID'] == '77777'}).to include({'FIRST_NAME' => 'Zaphod', 'LAST_NAME' => 'Zzzz', 'EMAIL_ADDRESS' => 'zzzz@berkeley.edu'})
      end

      it 'should not overwrite current-term instructor data with previous-term data' do
        expect(instructors.find { |i| i['LDAP_UID'] == '128533'}).to include({
          'FIRST_NAME' => 'Alan',
          'LAST_NAME' => 'Aaaa',
          'EMAIL_ADDRESS' => 'aaaa@berkeley.edu',
          'SIS_ID' => 'UID:128533'
        })
      end
    end

    context 'data with date formatting changed by Google' do
      let(:course_id) { '2015-B-34822' }
      let(:start_date) { '1/29/2015' }
      let(:end_date) { '5/3/2015' }
      before do
        merged_course_confirmations_csv.concat(
          "#{course_id},#{course_id},LGBT C146A LEC 002 REP SEXUALITY/LIT,Y,GWS/LGBT C146A LEC 002,LGBT,C146A,LEC,002,P,562283,10945601,Clarice,Cccc,cccc@berkeley.edu,23,Y,LGBT,G,Y,#{start_date},#{end_date}")
      end

      it 'should normalize dates' do
        task.run
        row = courses.find { |row| row['COURSE_ID'] == course_id }
        expect(row['START_DATE']).to eq '01-29-2015'
        expect(row['END_DATE']).to eq '05-03-2015'
      end
    end

    context 'data with suffixed course IDs' do
      before do
        merged_course_confirmations_csv.concat(
          "2015-B-#{ccn}_GSI,2015-B-#{ccn}_GSI,LGBT C146A LEC 001 REP SEXUALITY/LIT,,,LGBT,C146A,LEC,001,P,562283,10945601,Clarice,Cccc,cccc@berkeley.edu,23,Y,LGBT,G,,01-26-2015,05-11-2015")
        expect(Oec::Queries).to receive(:enrollments_for_cntl_nums)
          .with(term_code, [ccn])
          .and_return student_ids_for_ccn.map { |id| {'course_id' => "2015-B-#{ccn}", 'ldap_uid' => id} }
        expect(Oec::Queries).to receive(:students_for_cntl_nums)
          .with(term_code, array_including(ccn))
          .and_return(student_data_rows + student_data_rows_for_ccn)
      end
      let(:student_ids_for_ccn) { %w(1000 2000 3000) }
      let(:student_data_rows_for_ccn) do
        student_ids_for_ccn.map do |id|
          {
            'ldap_uid' => id,
            'first_name' => 'Val',
            'last_name' => 'Valid',
            'email_address' => 'valid@berkeley.edu',
            'sis_id' => random_id
          }
        end
      end

      shared_examples 'a smart suffix matcher' do
        it 'should match appropriate data to suffixed CCN' do
          task.run
          expect(courses.find { |course| course['COURSE_ID'] == "2015-B-#{ccn}_GSI"}).to be_present
          student_ids_for_ccn.each do |id|
            expect(course_students.find { |course_student| course_student['COURSE_ID'] == "2015-B-#{ccn}_GSI" && course_student['LDAP_UID'] == id }).to be_present
          end
          expect(course_instructors.find { |course_instructor| course_instructor['COURSE_ID'] == "2015-B-#{ccn}_GSI" && course_instructor['LDAP_UID'] == '562283'}).to be_present
        end
      end

      context 'data with suffixed course ID matching an ID without suffix' do
        let(:ccn) { '34821' }
        it_should_behave_like 'a smart suffix matcher'
      end
      context 'data with suffixed course ID matching no ID without suffix' do
        let(:ccn) { '50000' }
        it_should_behave_like 'a smart suffix matcher'
      end
    end
  end

  describe 'integrity validation' do
    let(:local_write) { 'Y' }
    before { allow(Rails.logger).to receive(:warn) }
    context 'mismatched enrollment data' do
      before do
        enrollment_data_rows << {'course_id' => '2016-B-99999', 'ldap_uid' => '99999999'}
      end
      it 'should report error' do
        expect(Rails.logger).to receive(:warn).with /Validation failed!/
        expect(Rails.logger).to receive(:warn).with /LDAP_UID 99999999 found in course_students but not students/
        task.run
      end
    end
    context 'mismatched student data' do
      before do
        student_data_rows << {
          'ldap_uid' => 99999999,
          'first_name' => 'Inter',
          'last_name' => 'Loper',
          'email_address' => 'interloper@berkeley.edu',
          'sis_id' => random_id
        }
      end
      it 'should report error' do
        expect(Rails.logger).to receive(:warn).with /Validation failed!/
        expect(Rails.logger).to receive(:warn).with /LDAP_UID 99999999 found in students but not course_students/
        task.run
      end
    end
  end

  context 'sftp command' do
    let(:local_write) { nil }

    before do
      parent_dir = mock_google_drive_item
      allow(fake_remote_drive).to receive(:find_nested).and_return parent_dir
      allow(fake_remote_drive).to receive(:check_conflicts_and_create_folder).and_return mock_google_drive_item
      allow(fake_remote_drive).to receive(:check_conflicts_and_upload)
    end

    after do
      Dir.glob(task.staging_dir.join "*#{Oec::PublishTask.name.demodulize.underscore}.log").each do |file|
        expect(File.open(file, 'rb').read).to include["#{tmp_publish_directory}/courses.csv", 'sftp://']
        FileUtils.rm_rf file
      end
    end

    it 'should run system command with datetime_to_publish in path' do
      expect(task).to receive(:system).and_return true
      expect(task.run).to be true
    end

    it 'should raise error when \'system\' returns false' do
      expect(task).to receive(:system).and_return false
      Rails.logger.warn "\n\nThe logs will get a verbose error message and stack trace during this test.\n"
      expect(task.run).to be_nil
    end
  end

end
