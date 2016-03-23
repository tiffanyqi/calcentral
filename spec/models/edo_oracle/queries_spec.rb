describe EdoOracle::Queries, :ignore => true do
  it_behaves_like 'an Oracle driven data source' do
    subject { EdoOracle::Queries }
  end

  it 'provides settings' do
    expect(EdoOracle::Queries.settings).to be Settings.edodb
  end

  describe '.get_instructing_sections', testext: true do
    let(:term) { Berkeley::Terms.fetch.campus['spring-2010'] }
    let(:uid) { '30' }
    it 'fetches expected data' do
      results = EdoOracle::Queries.get_instructing_sections(uid, [term])
      expect(results.count).to eq 17
      expected_keys = ['course_title', 'course_title_short', 'dept_name', 'catalog_id', 'primary', 'section_num', 'instruction_format', 'catalog_root', 'catalog_prefix', 'catalog_suffix']
      results.each do |result|
        expect(result['term_id']).to eq '2102'
        expected_keys.each do |expected_key|
          expect(result).to have_key(expected_key)
        end
      end
    end
  end

  describe '.get_enrolled_sections', testext: true do
    let(:term) { Berkeley::Terms.fetch.campus['spring-2010'] }
    let(:uid) { '767911' }
    it 'fetches expected data' do
      results = EdoOracle::Queries.get_enrolled_sections(uid, [term])
      expect(results.count).to eq 5
      expected_keys = ['section_id', 'term_id', 'course_title', 'course_title_short', 'dept_name', 'primary', 'section_num', 'instruction_format', 'display_name', 'catalog_id', 'catalog_root', 'catalog_prefix', 'catalog_suffix', 'enroll_limit', 'enroll_status', 'waitlist_position', 'unit', 'grading_basis']
      results.each do |result|
        expect(result['term_id']).to eq '2102'
        expected_keys.each do |expected_key|
          expect(result).to have_key(expected_key)
        end
      end
    end
  end

  describe '.get_sections_by_ids', :testext => true do
    # BIOENG C125 - Fall 2016
    let(:term_id) { '2168' }
    let(:section_ids) { ['26340', '26341'] }
    it 'returns sections specified by id array' do
      results = EdoOracle::Queries.get_sections_by_ids(term_id, section_ids)
      expect(results.count).to eq 2
      expect(results[0]['section_id']).to eq '26340'
      expect(results[1]['section_id']).to eq '26341'
      expected_keys = ['course_title', 'course_title_short', 'dept_name', 'catalog_id', 'primary', 'section_num', 'instruction_format', 'catalog_root', 'catalog_prefix', 'catalog_suffix']
      results.each do |result|
        expect(result['term_id']).to eq '2168'
        expected_keys.each do |expected_key|
          expect(result).to have_key(expected_key)
        end
      end
    end
  end

  describe '.get_section_meetings', :testext => true do
    # BIOENG C125 - Fall 2016
    let(:term_id) { '2168' }
    let(:section_ids) { ['26340', '26341'] }
    it 'returns meetings for section id specified' do
      results = EdoOracle::Queries.get_section_meetings(term_id, section_ids[0])
      expect(results.count).to eq 1
      expected_keys = ['section_id', 'term_id', 'session_id', 'location', 'meeting_days', 'meeting_start_time', 'meeting_end_time', 'print_in_schedule_of_classes']
      results.each do |result|
        expect(result['section_id']).to eq '26340'
        expect(result['term_id']).to eq '2168'
        expect(result['print_in_schedule_of_classes']).to eq 'Y'
        expected_keys.each do |expected_key|
          expect(result).to have_key(expected_key)
        end
      end
    end
  end
end
