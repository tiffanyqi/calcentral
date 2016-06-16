describe Calendar::Schedule do

  describe 'EDO DB meeting data' do
    let(:meeting_data) do
      {
        'meeting_days' => meeting_days,
        'meeting_start_time' => '14:00',
        'meeting_end_time' => '14:59',
        'meeting_start_date' => meeting_start_date,
        'meeting_end_date' => Time.parse('2016-12-09 00:00:00 UTC')
      }
    end
    subject { Calendar::Schedule::EdoOracle.from_meeting_data(meeting_data) }

    describe 'recurrence rule translation' do
      let(:meeting_start_date) { Time.parse('2016-08-24 00:00:00 UTC') }
      context 'a MWF class' do
        let(:meeting_days) { 'MOWEFR' }
        its([:recurrence]) { should eq Array.wrap 'RRULE:FREQ=WEEKLY;UNTIL=20161209T000000Z;BYDAY=MO,WE,FR' }
      end

      context 'a class that meets every day' do
        let(:meeting_days) { 'SUMOTUWETHFRSA' }
        its([:recurrence]) { should eq Array.wrap 'RRULE:FREQ=WEEKLY;UNTIL=20161209T000000Z;BYDAY=SU,MO,TU,WE,TH,FR,SA' }
      end

      context 'nil input' do
        let(:meeting_days) { nil }
        its([:recurrence]) { should be_nil }
      end

      context 'blank input' do
        let(:meeting_days) { '' }
        its([:recurrence]) { should be_nil }
      end
    end

    describe 'deriving first meeting time' do
      context 'a term that starts on a Thursday' do
        let(:meeting_start_date) { Time.parse('2016-08-25 00:00:00 UTC') }

        context 'a MWF class' do
          let(:meeting_days) { 'MOWEFR' }
          it 'should have its first meeting on a Friday' do
            expect(subject[:start][:dateTime]).to eq '2016-08-26T14:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2016-08-26T14:59:00.000-07:00'
          end
        end

        context 'a MW class' do
          let(:meeting_days) { 'MOWE' }
          it 'should have its first meeting on a Monday' do
            expect(subject[:start][:dateTime]).to eq '2016-08-29T14:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2016-08-29T14:59:00.000-07:00'
          end
        end

        context 'a Thursday class' do
          let(:meeting_days) { 'TH' }
          it 'should have its first meeting on a Thursday' do
            expect(subject[:start][:dateTime]).to eq '2016-08-25T14:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2016-08-25T14:59:00.000-07:00'
          end
        end

        context 'a Sunday-Monday class' do
          let(:meeting_days) { 'SUMO' }
          it 'should have its first meeting on a Sunday' do
            expect(subject[:start][:dateTime]).to eq '2016-08-28T14:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2016-08-28T14:59:00.000-07:00'
          end
        end

        context 'a Saturday class' do
          let(:meeting_days) { 'SA' }
          it 'should have its first meeting on a Saturday' do
            expect(subject[:start][:dateTime]).to eq '2016-08-27T14:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2016-08-27T14:59:00.000-07:00'
          end
        end
      end

      context 'a term that starts on a Sunday' do
        let(:meeting_start_date) { Time.parse('2016-08-28 00:00:00 UTC') }

        context 'a MWF class' do
          let(:meeting_days) { 'MOWEFR' }
          it 'should have its first meeting on a Monday' do
            expect(subject[:start][:dateTime]).to eq '2016-08-29T14:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2016-08-29T14:59:00.000-07:00'
          end
        end

        context 'a MW class' do
          let(:meeting_days) { 'MOWE' }
          it 'should have its first meeting on a Monday' do
            expect(subject[:start][:dateTime]).to eq '2016-08-29T14:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2016-08-29T14:59:00.000-07:00'
          end
        end

        context 'a Thursday class' do
          let(:meeting_days) { 'TH' }
          it 'should have its first meeting on a Thursday' do
            expect(subject[:start][:dateTime]).to eq '2016-09-01T14:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2016-09-01T14:59:00.000-07:00'
          end
        end

        context 'a Sunday class' do
          let(:meeting_days) { 'SUMO' }
          it 'should have its first meeting on a Sunday' do
            expect(subject[:start][:dateTime]).to eq '2016-08-28T14:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2016-08-28T14:59:00.000-07:00'
          end
        end

        context 'a Saturday class' do
          let(:meeting_days) { 'SA' }
          it 'should have its first meeting on a Saturday' do
            expect(subject[:start][:dateTime]).to eq '2016-09-03T14:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2016-09-03T14:59:00.000-07:00'
          end
        end
      end
    end
  end

  describe 'legacy meeting data' do
    let(:meeting_data) do
      {
        'meeting_days' => meeting_days,
        'term_yr' => '2013',
        'term_cd' => 'D'
      }
    end
    subject { Calendar::Schedule::CampusOracle.from_meeting_data(meeting_data) }

    describe 'translating recurrence rule' do
      context 'a MWF class' do
        let(:meeting_days) { ' M W F' }
        its([:recurrence]) { should eq Array.wrap 'RRULE:FREQ=WEEKLY;UNTIL=20131207T075959Z;BYDAY=MO,WE,FR' }
      end

      context 'a class that meets every day' do
        let(:meeting_days) { 'SMTWTFS' }
        its([:recurrence]) { should eq Array.wrap 'RRULE:FREQ=WEEKLY;UNTIL=20131207T075959Z;BYDAY=SU,MO,TU,WE,TH,FR,SA' }
      end

      context 'nil input' do
        let(:meeting_days) { nil }
        its([:recurrence]) { should be_nil }
      end

      context 'blank input' do
        let(:meeting_days) { '       ' }
        its([:recurrence]) { should be_nil }
      end
    end

    describe 'deriving first meeting time' do
      before { meeting_data.merge! meeting_times }

      # Fall 2013 started on a Thursday.
      context 'a term that starts on a Thursday' do
        context 'a MWF class' do
          let(:meeting_days) { ' M W F' }
          let(:meeting_times) { {
            'meeting_start_time' => '0237',
            'meeting_start_time_ampm_flag' => 'P',
            'meeting_end_time' => '0337',
            'meeting_end_time_ampm_flag' => 'P'
          } }
          it 'should have its first meeting on a Friday' do
            expect(subject[:start][:dateTime]).to eq '2013-08-30T14:37:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2013-08-30T15:37:00.000-07:00'
          end
        end

        context 'a MW class' do
          let(:meeting_days) { ' M W' }
          let(:meeting_times) { {
            'meeting_start_time' => '1001',
            'meeting_start_time_ampm_flag' => 'A',
            'meeting_end_time' => '1130',
            'meeting_end_time_ampm_flag' => 'A'
          } }
          it 'should have its first meeting on a Monday' do
            expect(subject[:start][:dateTime]).to eq '2013-09-02T10:01:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2013-09-02T11:30:00.000-07:00'
          end
        end

        context 'a Thursday class' do
          let(:meeting_days) { '    T' }
          let(:meeting_times) { {
            'meeting_start_time' => '1100',
            'meeting_start_time_ampm_flag' => 'P',
            'meeting_end_time' => '1159',
            'meeting_end_time_ampm_flag' => 'P'
          } }
          it 'should have its first meeting on a Thursday' do
            expect(subject[:start][:dateTime]).to eq '2013-08-29T23:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2013-08-29T23:59:00.000-07:00'
          end
        end

        context 'a Sunday-Monday class' do
          let(:meeting_days) { 'SM   ' }
          let(:meeting_times) { {
            'meeting_start_time' => '0237',
            'meeting_start_time_ampm_flag' => 'A',
            'meeting_end_time' => '0157',
            'meeting_end_time_ampm_flag' => 'P'
          } }
          it 'should have its first meeting on a Sunday' do
            expect(subject[:start][:dateTime]).to eq '2013-09-01T02:37:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2013-09-01T13:57:00.000-07:00'
          end
        end

        context 'a Saturday class' do
          let(:meeting_days) { '      S' }
          let (:meeting_times) { {
            'meeting_start_time' => '1200',
            'meeting_start_time_ampm_flag' => 'P',
            'meeting_end_time' => '1230',
            'meeting_end_time_ampm_flag' => 'P'
          } }
          it 'should have its first meeting on a Saturday' do
            expect(subject[:start][:dateTime]).to eq '2013-08-31T12:00:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2013-08-31T12:30:00.000-07:00'
          end
        end
      end

      context 'a term that starts on a Sunday' do
        let(:term) {
          Berkeley::Term.new({
            'term_cd' => 'D',
            'term_yr' => 2013,
            'term_name' => 'FAKE',
            'term_start_date' => '2013-09-01T00:00:00-07:00',
            'term_end_date' => '2013-12-05T00:00:00-07:00'
          })
        }
        let(:meeting_times) { {
          'meeting_start_time' => '0237',
          'meeting_start_time_ampm_flag' => 'P',
          'meeting_end_time' => '0337',
          'meeting_end_time_ampm_flag' => 'P'
        } }

        before do
          allow(Berkeley::Terms).to receive(:fetch).and_return double(campus: {'fall-2013' => term})
        end

        context 'a MWF class' do
          let(:meeting_days) { ' M W F' }
          it 'should have its first meeting on a Monday' do
            expect(subject[:start][:dateTime]).to eq '2013-09-02T14:37:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2013-09-02T15:37:00.000-07:00'
          end
        end

        context 'a MW class' do
          let(:meeting_days) { ' M W' }
          it 'should have its first meeting on a Monday' do
            expect(subject[:start][:dateTime]).to eq '2013-09-02T14:37:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2013-09-02T15:37:00.000-07:00'
          end
        end

        context 'a Thursday class' do
          let(:meeting_days) { '    T' }
          it 'should have its first meeting on a Thursday' do
            expect(subject[:start][:dateTime]).to eq '2013-09-05T14:37:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2013-09-05T15:37:00.000-07:00'
          end
        end

        context 'a Sunday class' do
          let(:meeting_days) { 'SM   ' }
          it 'should have its first meeting on a Sunday' do
            expect(subject[:start][:dateTime]).to eq '2013-09-01T14:37:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2013-09-01T15:37:00.000-07:00'
          end
        end

        context 'a Saturday class' do
          let(:meeting_days) { '      S' }
          it 'should have its first meeting on a Saturday' do
            expect(subject[:start][:dateTime]).to eq '2013-09-07T14:37:00.000-07:00'
            expect(subject[:end][:dateTime]).to eq '2013-09-07T15:37:00.000-07:00'
          end
        end
      end
    end
  end
end
