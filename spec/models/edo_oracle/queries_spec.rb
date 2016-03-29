describe EdoOracle::Queries, :ignore => true do
  # BIOENG C125 - Fall 2016
  let(:section_ids) { ['26340', '26341'] }
  let(:term_id) { '2168' }

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
      expected_keys = ['course_title', 'course_title_short', 'dept_name', 'catalog_id', 'primary', 'section_num', 'instruction_format', 'primary_associated_section_id', 'catalog_root', 'catalog_prefix', 'catalog_suffix']
      results.each do |result|
        expect(result['term_id']).to eq '2102'
        expect(result).to have_keys(expected_keys)
      end
    end
  end

  describe '.get_enrolled_sections', testext: true do
    let(:term) { Berkeley::Terms.fetch.campus['spring-2010'] }
    let(:uid) { '767911' }
    it 'fetches expected data' do
      results = EdoOracle::Queries.get_enrolled_sections(uid, [term])
      expect(results.count).to eq 5
      expected_keys = ['section_id', 'term_id', 'course_title', 'course_title_short', 'dept_name', 'primary', 'section_num', 'instruction_format', 'primary_associated_section_id', 'display_name', 'catalog_id', 'catalog_root', 'catalog_prefix', 'catalog_suffix', 'enroll_limit', 'enroll_status', 'waitlist_position', 'units', 'grade', 'grading_basis']
      results.each do |result|
        expect(result['term_id']).to eq '2102'
        expect(result).to have_keys(expected_keys)
      end
    end
  end

  describe '.get_sections_by_ids', :testext => true do
    it 'returns sections specified by id array' do
      results = EdoOracle::Queries.get_sections_by_ids(term_id, section_ids)
      expect(results.count).to eq 2
      expect(results[0]['section_id']).to eq '26340'
      expect(results[1]['section_id']).to eq '26341'
      expected_keys = ['course_title', 'course_title_short', 'dept_name', 'catalog_id', 'primary', 'section_num', 'instruction_format', 'primary_associated_section_id', 'catalog_root', 'catalog_prefix', 'catalog_suffix']
      results.each do |result|
        expect(result['term_id']).to eq '2168'
        expected_keys.each do |expected_key|
          expect(result).to have_key(expected_key)
        end
      end
    end
  end

  describe '.get_associated_secondary_sections', :testext => true do
    it 'returns a set of secondary sections' do
      results = EdoOracle::Queries.get_associated_secondary_sections(term_id, '31586')
      expect(results).to be_present
      expected_keys = ['course_title', 'course_title_short', 'dept_name', 'catalog_id', 'primary', 'section_num', 'instruction_format', 'primary_associated_section_id', 'catalog_root', 'catalog_prefix', 'catalog_suffix']
      results.each do |result|
        expect(result).to have_keys(expected_keys)
        expect(result['display_name']).to eq 'ESPM 155AC'
        expect(result['instruction_format']).to eq 'DIS'
        expect(result['primary']).to eq 'false'
        expect(result['term_id']).to eq term_id
      end
    end
  end


  describe '.get_section_meetings', :testext => true do
    it 'returns meetings for section id specified' do
      results = EdoOracle::Queries.get_section_meetings(term_id, section_ids[0])
      expect(results.count).to eq 1
      expected_keys = ['section_id', 'term_id', 'session_id', 'location', 'meeting_days', 'meeting_start_time', 'meeting_end_time', 'print_in_schedule_of_classes']
      results.each do |result|
        expect(result['section_id']).to eq '26340'
        expect(result['term_id']).to eq '2168'
        expect(result['print_in_schedule_of_classes']).to eq 'Y'
        expect(result).to have_keys(expected_keys)
      end
    end
  end

  describe '.get_section_instructors', :testext => true do
    let(:expected_keys) { ['person_name', 'first_name', 'last_name', 'ldap_uid', 'role_code', 'role_description'] }
    it 'returns instructors for section' do
      results = EdoOracle::Queries.get_section_instructors(term_id, section_ids[0])
      results.each do |result|
        expect(result).to have_keys(expected_keys)
      end
    end
  end

  describe '.terms', :testext => true do
    let(:expected_keys) { ['term_code', 'term_name', 'term_start_date', 'term_end_date'] }
    it 'returns terms' do
      results = EdoOracle::Queries.terms
      results.each do |result|
        expect(result).to have_keys(expected_keys)
      end
      result_codes = results.collect { |result| result['term_code'] }
      # check for Spring 2015 - Summer 2017 terms
      expect(result_codes).to include('2152', '2155', '2158', '2162', '2165', '2168', '2172', '2175')
    end
  end

end
