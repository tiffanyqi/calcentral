describe MediacastsController do

  let(:params) {
    {
      term_yr: course[:term_yr],
      term_cd: course[:term_cd],
      dept_name: course[:dept_name],
      catalog_id: course[:catalog_id]
    }
  }
  before do
    session['user_id'] = random_id
    allow(Settings.webcast_proxy).to receive(:fake).and_return true
    expect(Berkeley::Terms).to receive(:legacy?).and_return legacy
  end

  shared_examples 'a course with recordings' do
    before do
      courses_list = [
        {
          classes: [
            {
              sections: [
                {
                  ccn: expected_ccn.to_s,
                  section_number: random_id,
                  instruction_format: 'LEC'
                }
              ]
            }
          ]
        }
      ]
      expect(MyAcademics::Teaching).to receive(:new).and_return (teaching = double)
      expect(teaching).to receive(:courses_list_from_ccns).once.and_return courses_list
    end
    it 'should have audio and/or video' do
      get :get_media, params
      expect(response).to be_success
      media = JSON.parse(response.body)['media'][0]
      expect(media['ccn']).to eq expected_ccn
      expect(media['videos']).to eq expected_videos
      itunes_audio = media['iTunes']['audio']
      itunes_video = media['iTunes']['video']
      if expected_itunes_audio
        expect(itunes_audio).to include expected_itunes_audio
      else
        expect(itunes_audio).to be_nil
      end
      if expected_itunes_video
        expect(itunes_video).to include expected_itunes_video
      else
        expect(itunes_video).to be_nil
      end
    end
  end

  shared_examples 'a course with no recordings' do
    it 'should report no videos' do
      get :get_media, params
      expect(response).to be_success
      videos = JSON.parse(response.body)[:videos]
      expect(videos).to be_nil
    end
  end

  describe 'course data from EDO Oracle' do
    let(:legacy) { false }
    before do
      query_results = course[:ccn_set].map { |ccn| { 'section_id' => ccn.to_s } }
      term_id = Berkeley::TermCodes.to_edo_id course[:term_yr], course[:term_cd]
      expect(EdoOracle::Queries).to receive(:get_all_course_sections).with(
        term_id,
        course[:dept_name],
        course[:catalog_id]).and_return query_results
    end

    context 'course with recordings' do
      it_should_behave_like 'a course with recordings' do
        let(:astro_ccn_with_recordings) { 30598 }
        let(:course) {
          {
            term_yr: '2016',
            term_cd: 'D',
            dept_name: 'XASTRON',
            catalog_id: '10',
            ccn_set: [ astro_ccn_with_recordings ]
          }
        }
        let(:expected_ccn) { astro_ccn_with_recordings.to_s }
        let(:expected_videos) {
          [
            {
              'lecture' => '2016-08-25: A Grand Tour of the Cosmos',
              'youTubeId' => 'E8WBr8u7YoI',
              'recordingStartUTC' => '2015-08-25T15:07:00-08:00'
            }
          ]
        }
        let(:expected_itunes_audio) { nil }
        let(:expected_itunes_video) { nil }
      end
    end
  end

  describe 'course data from legacy Oracle' do
    let(:legacy) { true }

    before do
      query_results = course[:ccn_set].map { |ccn| { 'course_cntl_num' => ccn.to_s } }
      expect(CampusOracle::Queries).to receive(:get_all_course_sections).with(
        course[:term_yr],
        course[:term_cd],
        course[:dept_name],
        course[:catalog_id]).and_return query_results
    end

    context 'feature flag is false' do
      it_should_behave_like 'a course with no recordings' do
        let(:law_ccn_with_recordings) { 49688 }
        let(:course) {
          {
            term_yr: '2008',
            term_cd: 'D',
            dept_name: 'LAW',
            catalog_id: '2723',
            ccn_set: [ 1, law_ccn_with_recordings, 2 ]
          }
        }
        before { allow(Settings.features).to receive(:videos).and_return false }
      end
    end
    context 'empty ccn array' do
      it_should_behave_like 'a course with no recordings' do
        let(:course) {
          {
            term_yr: '2014',
            term_cd: 'D',
            dept_name: 'ECON',
            catalog_id: '101',
            ccn_set: []
          }
        }
      end
    end
    context 'not one ccn has associated videos' do
      it_should_behave_like 'a course with no recordings' do
        let(:course) {
          {
            term_yr: '2014',
            term_cd: 'B',
            dept_name: 'CHEM',
            catalog_id: '101',
            ccn_set: [1, 2, 3]
          }
        }
      end
    end
    context 'course with recordings' do
      it_should_behave_like 'a course with recordings' do
        let(:malay_ccn_with_recordings) { 85006 }
        let(:course) {
          {
            term_yr: '2014',
            term_cd: 'D',
            dept_name: 'MALAY/I',
            catalog_id: '100A',
            ccn_set: [ malay_ccn_with_recordings ]
          }
        }
        let(:expected_ccn) { malay_ccn_with_recordings.to_s }
        let(:expected_videos) { [] }
        let(:expected_itunes_audio) { nil }
        let(:expected_itunes_video) { '819827828' }
      end
    end
  end

end
