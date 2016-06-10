describe Textbooks::Proxy do

  # We do not use shared_examples so as to avoid hammering an external data source
  # with redundant requests.
  def it_is_a_normal_server_response
    expect(subject[:statusCode]).to be_blank
    expect(subject[:books][:items]).to be_an_instance_of Array
  end
  def it_has_at_least_one_title
    feed = subject[:books]
    expect(feed[:items]).to be_an_instance_of Array
    expect(feed[:items].length).to be > 1
    first_book = feed[:items][0]
    expect(first_book[:title]).to be_present
    expect(first_book[:author]).to be_present
  end

  let(:course_catalog) { '109G' }
  let(:dept) { 'POL SCI' }
  let(:section_numbers) { ['001'] }
  let(:slug) { 'fall-2013' }
  let(:proxy) do
    Textbooks::Proxy.new(
      course_catalog: course_catalog,
      dept: dept,
      fake: fake,
      section_numbers: section_numbers,
      slug: slug
    )
  end

  describe '#get' do
    subject { proxy.get }
    describe 'live testext tests enabled for order-independent expectations', testext: true, ignore: true do
      let(:fake) { false }
      context 'valid section numbers and term slug' do
        let(:course_catalog) { 'R1A' }
        let(:dept) { 'COLWRIT' }
        let(:section_numbers) { ['001'] }
        let(:slug) { 'summer-2015' }
        it 'produces the expected textbook feed' do
          it_is_a_normal_server_response
          it_has_at_least_one_title
          book_list = subject[:books][:items]
          first_book = book_list[0]
          [:isbn, :image, :amazonLink, :cheggLink, :oskicatLink, :googlebookLink, :bookstoreInfo].each do |key|
            expect(first_book[key]).to be_present
          end
          expect(first_book[:image]).to_not match /http:/
        end
      end

      context 'an unknown section number' do
        let(:course_catalog) { '102' }
        let(:dept) { 'MCELLBI' }
        let(:section_numbers) { ['101'] }
        let(:slug) { 'summer-2015' }
        it 'returns a helpful message' do
          it_is_a_normal_server_response
          feed = subject[:books]
          expect(feed[:bookUnavailableError]).to eq 'Currently, there is no textbook information for this course. Check again later for updates, or contact the <a href="https://calstudentstore.berkeley.edu/textbook" target="_blank">ASUC book store</a>.'
        end
      end

      context 'multiple section numbers' do
        let(:course_catalog) { '102' }
        let(:dept) { 'MCELLBI' }
        let(:section_numbers) { ['101', '001'] }
        let(:slug) { 'summer-2015' }
        it 'finds the one with books' do
          it_is_a_normal_server_response
          it_has_at_least_one_title
        end
      end
    end

    context 'fake proxy' do
      let(:fake) { true }

      context 'good fixture data' do
        it 'properly transforms bookstore feed' do
          it_is_a_normal_server_response
          it_has_at_least_one_title
          items = subject[:books][:items]
          expect(items[1][:author]).to eq 'SIDES'
          expect(items[1][:title]).to eq 'CAMPAIGNS+ELECTIONS 2012 ELECTION UPD. (Required)'
        end
      end

      context 'feed including malformed item' do
        before do
          proxy.override_json do |json|
            json.first['materials'][3] = {
              ean: 'No Number Nonsense',
              title: ' ()',
              author: nil
            }
          end
        end
        it 'logs error and skips bad entry' do
          expect(Rails.logger).to receive(:error).with /invalid ISBN/
          it_is_a_normal_server_response
          expect(subject[:books][:items]).to have(3).items
        end
      end

      context 'course catalog with fewer than three characters' do
        before { allow_any_instance_of(Berkeley::Term).to receive(:legacy?).and_return legacy }
        let(:course_catalog) { '1A' }
        let(:url) { proxy.bookstore_link section_numbers }

        def encoded_course_param(value)
          "%22course%22:%22#{value}%22"
        end

        context 'legacy term' do
          let(:legacy) { true }
          it 'does not zero-pad course catalog' do
            expect(url).to include encoded_course_param('1A')
          end
        end
        context 'Campus Solutions term' do
          let(:legacy) { false }
          it 'zero-pads course catalog' do
            expect(url).to include encoded_course_param('01A')
          end
        end
      end
    end
  end

  describe '#get_as_json' do
    include_context 'it writes to the cache at least once'
    let(:fake) { false }
    let(:json) { proxy.get_as_json }
    it 'returns proper JSON' do
      expect(json).to be_present
      parsed = JSON.parse(json)
      expect(parsed).to be
      unless parsed['statusCode'] && parsed['statusCode'] >= 400
        expect(parsed['books']).to be
      end
    end
    context 'when the bookstore server has problems' do
      before do
        stub_request(:any, /#{Regexp.quote(Settings.textbooks_proxy.base_url)}.*/).to_raise(Errno::EHOSTUNREACH)
      end
      it 'returns a error status code and message' do
        parsed = JSON.parse(json)
        expect(parsed['statusCode']).to be >= 400
        expect(parsed['body']).to be_present
      end
    end

    it_should_behave_like 'a proxy logging errors' do
      subject { json }
    end
  end

end
