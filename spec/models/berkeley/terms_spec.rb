describe Berkeley::Terms do
  let(:options) {{fake_now: fake_now}}
  subject {Berkeley::Terms.fetch(options)}

  shared_examples 'a list of campus terms' do
    its(:campus) {should be_is_a Hash}
    it 'is in reverse chronological order' do
      previous_term = nil
      subject.campus.each do |slug, term|
        expect(term).to be_is_a Berkeley::Term
        expect(slug).to eq term.slug
        expect(term.sis_term_status).to be_present
        if previous_term
          expect(term.start).to be < previous_term.start
          expect(term.end).to be < previous_term.end
        end
        previous_term = term
      end
    end
  end

  context 'working against test data', if: CampusOracle::Queries.test_data? do
    let(:fake_now) {Settings.terms.fake_now.to_datetime}
    it 'finds the legacy SIS CT term' do
      expect(subject.sis_current_term.slug).to eq 'fall-2013'
    end
    context 'in Fall 2013' do
      let(:fake_now) {DateTime.parse('2013-10-10')}
      it_behaves_like 'a list of campus terms'
      its('current.slug') {should eq 'fall-2013'}
      its('running.slug') {should eq 'fall-2013'}
      its('next.slug') {should eq 'spring-2014'}
      its('future.slug') {should eq 'summer-2014'}
      its('grading_in_progress') {should be_nil}
    end
    context 'during final exams' do
      let(:fake_now) {DateTime.parse('2013-12-14')}
      it_behaves_like 'a list of campus terms'
      its('current.slug') {should eq 'fall-2013'}
      its('running.slug') {should eq 'fall-2013'}
      its('next.slug') {should eq 'spring-2014'}
      its('future.slug') {should eq 'summer-2014'}
      its('grading_in_progress') {should be_nil}
    end
    context 'between terms' do
      let(:fake_now) {DateTime.parse('2013-12-31')}
      it_behaves_like 'a list of campus terms'
      its('current.slug') {should eq 'spring-2014'}
      its(:running) {should be_nil}
      its('next.slug') {should eq 'summer-2014'}
      its('future.slug') {should eq 'fall-2014'}
      its('grading_in_progress.slug') {should eq 'fall-2013'}
    end
    context 'in last of available terms' do
      let(:fake_now) {DateTime.parse('2016-10-27')}
      it_behaves_like 'a list of campus terms'
      its('current.slug') {should eq 'fall-2016'}
      its('running.slug') {should eq 'fall-2016'}
      its(:next) {should be_nil}
      its(:future) {should be_nil}
      its('grading_in_progress') {should be_nil}
    end
    context 'limiting semester range' do
      let(:options) {{oldest: 'summer-2012'}}
      it_behaves_like 'a list of campus terms'
      it 'does not include older semesters' do
        expect(subject.campus.keys.last).to eq 'summer-2012'
      end
    end
  end

  context 'legacy source-of-record checks' do
    before { allow(Settings.terms).to receive(:legacy_cutoff).and_return legacy_cutoff }
    subject { Berkeley::Terms.fetch.campus['spring-2014'] }
    context 'term is before legacy cutoff' do
      let(:legacy_cutoff) { 'summer-2014' }
      its(:legacy?) { should eq true }
      it 'reports legacy status from class methods' do
        expect(Berkeley::Terms.legacy?('2014', 'B')).to eq true
        expect(Berkeley::Terms.campus_solutions?('2014', 'B')).to eq false
      end
    end
    context 'term is equal to legacy cutoff' do
      let(:legacy_cutoff) { 'spring-2014' }
      its(:legacy?) { should eq true }
      it 'reports legacy status from class methods' do
        expect(Berkeley::Terms.legacy?('2014', 'B')).to eq true
        expect(Berkeley::Terms.campus_solutions?('2014', 'B')).to eq false
      end
    end
    context 'term is after legacy cutoff' do
      let(:legacy_cutoff) { 'fall-2013' }
      its(:legacy?) { should eq false }
      it 'reports Campus Solutions status from class methods' do
        expect(Berkeley::Terms.legacy?('2014', 'B')).to eq false
        expect(Berkeley::Terms.campus_solutions?('2014', 'B')).to eq true
      end
    end
    context 'term not found' do
      let(:legacy_cutoff) { 'fall-2013' }
      it 'returns false from class methods' do
        expect(Berkeley::Terms.legacy?('1969', 'B')).to eq false
        expect(Berkeley::Terms.campus_solutions?('1969', 'B')).to eq false
      end
    end
  end

  describe '.legacy_group' do
    let(:terms) { Berkeley::Terms.fetch.campus.values[0..1] }
    it 'returns terms grouped by data source' do
      terms[0].instance_eval { @is_legacy = false }
      terms[1].instance_eval { @is_legacy = true }
      result = Berkeley::Terms.legacy_group(terms)
      expect(result[:legacy].count).to eq 1
      expect(result[:legacy][0]).to eq terms[1]
      expect(result[:sisedo].count).to eq 1
      expect(result[:sisedo][0]).to eq terms[0]
    end
  end

end
