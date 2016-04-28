describe CampusSolutions::UserSearch do
  let(:name_1) { 'Prince Rogers' }
  let(:name_2) { nil }
  let(:affiliations) { %w(ADMT_UX STUDENT UNDERGRAD) }
  let(:proxy) { CampusSolutions::UserSearch.new(fake: true, name_1: name_1, name_2: name_2, affiliations: affiliations) }
  subject { proxy.get }

  it_should_behave_like 'a simple proxy that returns errors'
  it_should_behave_like 'a proxy that got data successfully'

  context 'fake proxy' do
    context 'missing argument' do
      let(:name_1) { nil }
      it 'should complain about missing NAME1 param' do
        expect { CampusSolutions::UserSearch.new }.to raise_error ArgumentError, 'Arg :name_1 is required in user search'
      end
    end
    context 'valid args' do
      context 'no NAME2 when optional arg is nil' do
        it 'should exclude NAME2 param' do
          expect(proxy.url).to_not include 'NAME2'
        end
      end
      context 'parsed feed' do
        let(:name_2) { 'N,l$&?' }

        it 'should properly escape NAME2 param' do
          url = proxy.url
          %w(Prince+Rogers NAME2=N%2Cl%24%26%3F AFFILIATIONS%5B%5D=ADMT_UX&AFFILIATIONS%5B%5D=STUDENT&AFFILIATIONS%5B%5D=UNDERGRAD).each { |substring| expect(url).to include substring }
        end
        it 'should populate feed' do
          expected_users = [
            {
              ldapUid: '22',
              sid: '3333333333',
              name: 'Day, Morris',
              academicPrograms: [
                {
                  term: '2015 Spring',
                  career: 'UNDERGRAD',
                  plan: '25428',
                  planDescription: 'History BA',
                  program: 'GACAD',
                  programDescription: 'Undergraduate Academic Programs'
                },
                {
                  term: '2016 Fall',
                  career: 'GRAD',
                  plan: '25429',
                  planDescription: 'History MS',
                  program: 'GACAD',
                  programDescription: 'Graduate Academic Programs'
                }
              ]
            },
            {
              ldapUid: '55555',
              sid: '6666666666',
              name: 'Jam, Jimmy',
              academicPrograms: []
            }
          ]
          expect(subject[:feed][:users]).to eq expected_users
        end
      end
    end
  end

end
