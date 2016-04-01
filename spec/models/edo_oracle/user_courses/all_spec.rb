describe EdoOracle::UserCourses::All do

  subject { described_class.new(user_id: random_id).get_all_campus_courses }

  before do
    allow(Settings.terms).to receive(:legacy_cutoff).and_return 'fall-2013'
  end

  context 'EDO DB errors' do
    before do
      allow(EdoOracle::Queries).to receive(:get_instructing_sections)
        .and_raise ActiveRecord::JDBCError, "Hornets' nest in the btree"
    end
    it 'logs errors and returns a blank hash' do
      expect(Rails.logger).to receive(:error).with /JDBCError/
      expect(subject).to eq({})
    end
  end

end
