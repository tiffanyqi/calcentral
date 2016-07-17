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
        expect(term.campus_solutions_id).to be_present
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
    context 'in Spring 2016' do
      let(:fake_now) {DateTime.parse('2016-03-10')}
      it_behaves_like 'a list of campus terms'
      its('current.slug') {should eq 'spring-2016'}
      its('running.slug') {should eq 'spring-2016'}
      its('next.slug') {should eq 'summer-2016'}
      its('future.slug') {should eq 'fall-2016'}
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
      let(:fake_now) {DateTime.parse('2017-1-27')}
      it_behaves_like 'a list of campus terms'
      its('current.slug') {should eq 'spring-2017'}
      its('running.slug') {should eq 'spring-2017'}
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
    let(:fake_now) {Settings.terms.fake_now.to_datetime}
    before { allow(Settings.terms).to receive(:legacy_cutoff).and_return legacy_cutoff }
    let(:term_slug) {'spring-2014'}
    context 'term is before legacy cutoff' do
      let(:legacy_cutoff) { 'summer-2014' }
      it 'reports legacy status' do
        expect(subject.campus[term_slug].legacy?).to eq true
        expect(Berkeley::Terms.legacy?('2014', 'B')).to eq true
      end
    end
    context 'term is equal to legacy cutoff' do
      let(:legacy_cutoff) { 'spring-2014' }
      it 'reports legacy status' do
        expect(subject.campus[term_slug].legacy?).to eq true
        expect(Berkeley::Terms.legacy?('2014', 'B')).to eq true
      end
    end
    context 'term is after legacy cutoff' do
      let(:fake_now) {DateTime.parse('2016-07-27')}
      let(:legacy_cutoff) { 'fall-2015' }
      let(:term_slug) {'spring-2016'}
      it 'reports Campus Solutions status' do
        expect(subject.campus[term_slug].legacy?).to eq false
        expect(Berkeley::Terms.legacy?('2016', 'B')).to eq false
      end
    end
    context 'term not found' do
      let(:legacy_cutoff) { 'fall-2013' }
      it 'returns false from class methods' do
        expect(subject.campus['spring-2017']).to be_nil
        expect(Berkeley::Terms.legacy?('1969', 'B')).to eq false
      end
    end
  end

  describe '.legacy_group' do
    before { allow(Settings.features).to receive(:hub_term_api).and_return true }
    let(:terms) { Berkeley::Terms.fetch(fake_now: DateTime.parse('2016-07-12')).campus.values[0..2] }
    it 'returns terms grouped by data source' do
      result = Berkeley::Terms.legacy_group(terms)
      expect(result[:legacy].count).to eq 1
      expect(result[:legacy][0]).to eq terms[2]
      expect(result[:sisedo].count).to eq 2
      expect(result[:sisedo][0]).to eq terms[0]
    end
  end

  describe '#fetch_terms_from_api' do
    before { allow(Settings.features).to receive(:hub_term_api).and_return true }
    subject { Berkeley::Terms.new(fake: true, fake_now: DateTime.parse('2016-07-12')) }
    it 'finds all post-legacy data' do
      terms = subject.fetch_terms_from_api
      expect(terms.length).to eq 2
      expect(terms[0].to_english).to eq 'Spring 2017'
      expect(terms[1].to_english).to eq 'Fall 2016'
    end
    context 'honors the legacy SIS cutoff' do
      before { allow(Settings.terms).to receive(:legacy_cutoff).and_return 'spring-2016' }
      it 'finds all post-legacy data' do
        terms = subject.fetch_terms_from_api
        expect(terms.length).to eq 3
        expect(terms[0].to_english).to eq 'Spring 2017'
        expect(terms[1].to_english).to eq 'Fall 2016'
        expect(terms[2].to_english).to eq 'Summer 2016'
        expect(subject.sis_current_term.to_english).to eq 'Summer 2016'
      end
    end
  end

  describe 'short cache lifespan when API has errors' do
    before { allow(Settings.features).to receive(:hub_term_api).and_return true }
    include_context 'short-lived cache write of Hash on failures'
    include_context 'expecting logs from server errors'
    let(:fake_now) {DateTime.parse('2016-06-10')}
    let(:uri) { URI.parse(Settings.hub_term_proxy.base_url) }
    let(:status) { 502 }
    before do
      allow(Settings.hub_term_proxy).to receive(:fake).and_return false
      stub_request(:any, /.*#{uri}.*/).to_return(status: status)
    end
    it 'reports an error' do
      expect(subject[:statusCode]).to eq 503
    end
  end

  context 'Hub Term API feature flag disabled' do
    before { allow(Settings.features).to receive(:hub_term_api).and_return false }
    let(:fake_now) {DateTime.parse('2016-06-16')}
    it 'uses only the legacy DB, even for non-legacy semesters' do
      expect(HubTerm::Proxy).to receive(:new).never
      expect(subject.next.legacy?).to be_falsey
      expect(subject.future).to be_nil
    end
  end

end
