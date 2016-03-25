describe EdoOracle::UserCourses::Base do

  RSpec::Matchers.define :terms_following_cutoff do |cutoff|
    match do |terms|
      term_ids = terms.map &:campus_solutions_id
      term_ids.present? && term_ids.all? { |term_id| term_id > cutoff }
    end
  end

  it 'should query non-legacy terms only' do
    allow(Settings.terms).to receive(:legacy_cutoff).and_return 'summer-2013'
    expect(EdoOracle::Queries).to receive(:get_enrolled_sections).with(anything, terms_following_cutoff('2135')).and_return []
    described_class.new(user_id: random_id).merge_enrollments({})
  end

  let(:base_course_data) do
    {
      'catalog_id' => '74',
      'catalog_prefix' => nil,
      'catalog_root' => '74',
      'catalog_suffix' => nil,
      'course_title' => 'Introduction to Selected Musics of the World',
      'course_title_short' => 'INTR MUSICS WORLD',
      'dept_name' => 'MUSIC',
      'display_name' => 'MUSIC 74',
      'term_id' => '2168',
    }
  end

  describe 'enrolled sections merge' do
    let(:enrollment_query_results) do
      [
        base_course_data.merge({
          'enroll_limit' => '40',
          'enroll_status' => 'E',
          'grade' => 'B',
          'grading_basis' => 'GRD',
          'instruction_format' => 'LEC',
          'primary' => true,
          'section_id' => '44203',
          'section_num' => '001',
          'units' => '4',
          'wait_list_seq_num' => nil
        }),
        base_course_data.merge({
          'enroll_limit' => '50',
          'enroll_status' => 'W',
          'grade' => nil,
          'grading_basis' => 'PNP',
          'instruction_format' => 'LEC',
          'primary' => true,
          'section_id' => '44206',
          'section_num' => '002',
          'units' => '3',
          'wait_list_seq_num' => nil
        }),
        base_course_data.merge({
          'enroll_limit' => '40',
          'enroll_status' => 'E',
          'grade' => nil,
          'grading_basis' => nil,
          'instruction_format' => 'DIS',
          'primary' => false,
          'section_id' => '44214',
          'section_num' => '201',
          'units' => nil,
          'wait_list_seq_num' => nil
        })
      ]
    end
    before { allow(EdoOracle::Queries).to receive(:get_enrolled_sections).and_return enrollment_query_results }
    let(:feed) { {}.tap { |feed| EdoOracle::UserCourses::Base.new(user_id: random_id).merge_enrollments feed } }
    subject { feed['2016-D'] }
    its(:size) { should eq 1 }
    it 'includes only course info at the course level' do
      course = subject.first
      expect(course[:catid]).to eq '74'
      expect(course[:course_catalog]).to eq '74'
      expect(course[:course_code]).to eq 'MUSIC 74'
      expect(course[:dept]).to eq 'MUSIC'
      expect(course[:emitter]).to eq 'Campus'
      expect(course[:id]).to eq 'music-74-2016-D'
      expect(course[:name]).to eq 'Introduction to Selected Musics of the World'
      expect(course[:role]).to eq 'Student'
      expect(course[:slug]).to eq 'music-74'
      expect(course[:term_cd]).to eq 'D'
      expect(course[:term_id]).to eq '2168'
      expect(course[:term_yr]).to eq '2016'
    end
    it 'includes per-section information' do
      course = subject.first
      expect(course[:sections].size).to eq 3
      [course[:sections], enrollment_query_results].transpose.each do |section, enrollment|
        expect(section[:ccn]).to eq enrollment['section_id']
        expect(section[:instruction_format]).to eq enrollment['instruction_format']
        expect(section[:section_label]).to eq "#{enrollment['instruction_format']} #{enrollment['section_num']}"
        expect(section[:section_number]).to eq enrollment['section_num']
        if enrollment['primary']
          expect(section[:grading_basis]).to eq enrollment['grading_basis']
          expect(section[:is_primary_section]).to eq true
          expect(section[:units]).to eq enrollment['units']
        else
          expect(section[:is_primary_section]).to eq false
          expect(section).not_to include(:grading_basis, :units)
        end
        if enrollment['enroll_status'] == 'W'
          expect(section[:enroll_limit]).to eq enrollment['enroll_limit'].to_i
          expect(section[:waitlistPosition]).to eq enrollment['wait_list_seq_num'].to_i
        else
          expect(section).not_to include(:enroll_limit, :waitlistPosition)
        end
      end
    end
    it 'includes only non-blank grades' do
      course = subject.first
      expect(course[:sections][0][:grade]).to eq 'B'
      expect(course[:sections][1]).not_to include(:grade)
    end
  end

  describe 'instructing sections merge' do
    let(:instructing_query_results) do
      [
        base_course_data.merge({
          'instruction_format' => 'LEC',
          'primary' => true,
          'section_id' => '44206',
          'section_num' => '001'
        }),
        base_course_data.merge({
          'instruction_format' => 'LEC',
          'primary' => true,
          'section_id' => '44207',
          'section_num' => '002'
        }),
        base_course_data.merge({
          'catalog_id' => '99C',
          'catalog_prefix' => nil,
          'catalog_root' => '99',
          'catalog_suffix' => 'C',
          'course_title' => 'The Stooges in Context',
          'course_title_short' => 'STGS CNTXT',
          'dept_name' => 'MUSIC',
          'display_name' => 'MUSIC 99C',
          'instruction_format' => 'LEC',
          'primary' => true,
          'section_id' => '44807',
          'section_num' => '001'
        })
      ]
    end
    before { allow(EdoOracle::Queries).to receive(:get_instructing_sections).and_return instructing_query_results }
    let(:feed) { {}.tap { |feed| EdoOracle::UserCourses::Base.new(user_id: random_id).merge_instructing feed } }
    subject { feed['2016-D'] }

    it 'sorts out sections based on course code' do
      expect(subject).to have(2).items
      expect(subject.find { |course| course[:course_code] == 'MUSIC 74'}[:sections]).to have(2).items
      expect(subject.find { |course| course[:course_code] == 'MUSIC 99C'}[:sections]).to have(1).items
    end

    it 'includes course data without enrollment-specific properties' do
      subject.each do |course|
        expect(course.keys).to include(:catid, :course_catalog, :course_code, :dept, :emitter, :id, :name, :role, :sections, :slug, :term_cd, :term_id, :term_yr)
        expect(course[:role]).to eq 'Instructor'
        course[:sections].each do |section|
          expect(section.keys).to include(:ccn, :instruction_format, :is_primary_section, :section_label, :section_number)
          expect(section.keys).to include(:units) if section[:is_primary_section]
          expect(section.keys).not_to include(:grading_basis, :enroll_limit, :waitlistPosition)
        end
      end
    end
  end

  describe '#course_ids_from_row' do
    let(:row) {{
      'catalog_id' => '0109AL',
      'dept_name' => 'MEC ENG/I,RES',
      'display_name' => 'MEC ENG/I,RES 0109AL',
      'term_id' => '2168'
    }}
    subject { EdoOracle::UserCourses::Base.new(user_id: random_id).course_ids_from_row row }
    its([:slug]) { should eq 'mec_eng_i_res-0109al' }
    its([:id])  {should eq 'mec_eng_i_res-0109al-2016-D' }
    its([:course_code]) { should eq 'MEC ENG/I,RES 0109AL' }
  end

  describe '#row_to_feed_item' do
    let(:row) {{
      'catalog_id' => '0109AL',
      'dept_name' => 'MEC ENG/I,RES',
      'term_id' => '2168',
      'course_title' => course_title,
      'course_title_short' => 'KOLLAPS'
    }}
    subject { EdoOracle::UserCourses::Base.new(user_id: random_id).row_to_feed_item(row, {}) }
    context 'course has a nice long title' do
      let(:course_title) { 'Failure Analysis of Load-Bearing Structures' }
      it 'uses the official title' do
        expect(subject[:name]).to eq course_title
      end
    end
    context 'course has a null COURSE_TITLE column' do
      let(:course_title) { nil }
      it 'falls back to short title' do
        expect(subject[:name]).to eq 'KOLLAPS'
      end
    end
  end

end
