describe MyRegistrations::MyRegistrations do
  let(:model) { MyRegistrations::MyRegistrations.new('61889') }
  before(:each) do
    allow(model).to receive(Settings.terms.legacy_cutoff).and_return 'summer-2016'
    allow(model).to receive(:get_registrations).and_return ({
      "affiliations" => "GRAD",
      "registrations" => [
       {
         "term" => {
           "id" => 2162,
           "name" => "2016 Spring",
           "academicYear" => "2017"
         }
       },
       {
         "term" => {
           "id" => 2165,
           "name" => "2016 Summer",
           "academicYear" => "2017"
         }
       },
       {
         "term" => {
           "id" => 2168,
           "name" => "2016 Fall",
           "academicYear" => "2017"
         }
       },
       {
       "term" => {
         "id" => 2171,
         "name" => "2017 Spring",
         "academicYear" => "2018"
       }
     }
    ]})
  end

  context 'fully populated berkeley terms' do
    before do
      allow(model).to receive(:get_terms).and_return ({
        current: {id: 2165, name: 'Summer 2016'},
        running: {id: 2165, name: 'Summer 2016'},
        sis_current_term: {id: 2168, name: 'Fall 2016'},
        next: {id: 2168, name: 'Fall 2016'},
        future: {id: 2171, name: 'Spring 2017'}
      })
    end
    it 'returns all matched terms' do
      matched_terms = model.get_feed_internal
      expect(matched_terms[:registrations][2165][0][:isLegacy]).to eq true
      expect(matched_terms[:registrations][2168][0]["term"]["id"]).to eq 2168
      expect(matched_terms[:registrations][2171][0]["term"]["id"]).to eq 2171
    end
  end

  context 'some populated berkeley terms' do
    before do
      allow(model).to receive(:get_terms).and_return ({
        current: nil,
        running: nil,
        sis_current_term: nil,
        next: {id: 2168, name: 'Fall 2016'},
        future: {id: 2171, name: 'Spring 2017'}
      })
    end
    it 'returns all matched terms' do
      matched_terms = model.get_feed_internal
      expect(matched_terms[:registrations][2165]).to be_nil
      expect(matched_terms[:registrations][2168][0]["term"]["id"]).to eq 2168
      expect(matched_terms[:registrations][2171][0]["term"]["id"]).to eq 2171
    end
  end

  context 'no populated berkeley terms' do
    before do
      allow(model).to receive(:get_terms).and_return ({
        current: nil,
        running: nil,
        sis_current_term: nil,
        next: nil,
        future: nil
      })
    end
    it 'returns no matched terms' do
      matched_terms = model.get_feed_internal
      expect(matched_terms[:registrations][2165]).to be_nil
      expect(matched_terms[:registrations][2168]).to be_nil
      expect(matched_terms[:registrations][2171]).to be_nil
    end
  end

end
