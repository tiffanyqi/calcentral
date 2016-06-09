describe EdoOracle::Calendar do

  context 'querying for courses' do
    before do
      allow(Berkeley::Terms).to receive(:fetch).and_return double(
        current: double(campus_solutions_id: '2162', legacy?: spring_legacy),
        next: double(campus_solutions_id: '2165', legacy?: summer_legacy),
        future: double(campus_solutions_id: '2168', legacy?: fall_legacy)
      )
    end
    shared_examples 'query for correct terms' do
      it 'should include proper term sql' do
        expect(EdoOracle::Calendar).to receive(:safe_query) do |sql|
          expect(sql).to include expected_sql
        end
        EdoOracle::Calendar.get_all_courses
      end
    end
    include_examples 'query for correct terms' do
      let(:spring_legacy) { true }
      let(:summer_legacy) { true }
      let(:fall_legacy) { false }
      let(:expected_sql) { 'mtg."term-id" IN (2168)' }
    end
    include_examples 'query for correct terms' do
      let(:spring_legacy) { true }
      let(:summer_legacy) { false }
      let(:fall_legacy) { false }
      let(:expected_sql) { 'mtg."term-id" IN (2165,2168)' }
    end
    include_examples 'query for correct terms' do
      let(:spring_legacy) { false }
      let(:summer_legacy) { false }
      let(:fall_legacy) { false }
      let(:expected_sql) { 'mtg."term-id" IN (2162,2165,2168)' }
    end
  end

  context 'querying for students' do
    let(:term_id) { '2168' }
    let(:course_id) { '7309' }
    let(:run_query) { EdoOracle::Calendar.get_whitelisted_students_in_course(users, term_id, course_id) }
    context 'empty users list' do
      let(:users) { [] }
      it 'does not query and returns empty results' do
        expect(EdoOracle::Calendar).not_to receive :safe_query
        expect(run_query).to eq []
      end
    end
    shared_examples 'properly chunked whitelist' do
      it 'should include proper UID sql' do
        expect(EdoOracle::Calendar).to receive(:safe_query) do |sql|
          expect(sql).to include expected_sql
        end
        run_query
      end
    end
    context 'fewer than 1000 users in whitelist' do
      let(:users) { (100..105).map { |uid| double(uid: uid) } }
      include_examples 'properly chunked whitelist' do
        let(:expected_sql) { '(enroll."CAMPUS_UID" IN (100,101,102,103,104,105))' }
      end
    end
    context 'more than 1000 users in whitelist' do
      let(:users) { (1000..2005).map { |uid| double(uid: uid) } }
      include_examples 'properly chunked whitelist' do
        let(:expected_sql) { '1996,1997,1998,1999) OR enroll."CAMPUS_UID" IN (2000,2001,2002,2003,2004,2005))' }
      end
    end
  end

end
