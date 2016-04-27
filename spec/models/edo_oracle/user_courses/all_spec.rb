describe EdoOracle::UserCourses::All do

  subject { described_class.new(user_id: random_id).get_all_campus_courses }

  before do
    allow(Settings.terms).to receive(:legacy_cutoff).and_return 'fall-2013'
  end

  context 'EDO DB errors' do
    before do
      # Fetch CampusOracle terms in advance before we start forcing database errors.
      fetched_terms = Berkeley::Terms.fetch
      allow(Berkeley::Terms).to receive(:fetch).and_return fetched_terms

      allow(Settings.edodb).to receive(:fake).and_return false
      allow_any_instance_of(ActiveRecord::ConnectionAdapters::JdbcAdapter).to receive(:select_all)
        .and_raise ActiveRecord::JDBCError, "Hornets' nest in the btree"
    end
    it 'logs errors and returns a blank hash' do
      expect(Rails.logger).to receive(:error).with(/JDBCError/).at_least :once
      expect(subject).to eq({})
    end
  end

end
