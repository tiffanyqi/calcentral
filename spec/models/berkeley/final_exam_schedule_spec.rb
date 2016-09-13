describe Berkeley::FinalExamSchedule do

  # {
  #   B-M-8:00A=>{:exam_day=>"Monday",:exam_time=>"8-11A",:exam_slot=>1},
  #   B-CHEM 1A=>{:exam_day=>"Wednesday",:exam_time=>"8-11A",:exam_slot=>9},
  #   ...
  # } Each key is the term_code - one_day - start_time, which maps to a exam slot, time, and day
  #   If the course is an exception, the key is term_code - course_code
  let(:final_exam_logic) do
    Berkeley::FinalExamSchedule.fetch
  end

  context 'as a student' do
    it 'should parse the csvs correctly' do
      # hardcoded expectances, if one of these fails, make sure csv and test is updated
      expect(final_exam_logic['B-M-8:00A'][:exam_day]).to eq 'Monday'
      expect(final_exam_logic['B-M-8:00A'][:exam_time]).to eq '8-11A'
      expect(final_exam_logic['B-M-8:00A'][:exam_slot]).to eq '1'
      expect(final_exam_logic['B-W-8:00A'][:exam_day]).to eq 'Monday'
      expect(final_exam_logic['B-W-8:00A'][:exam_time]).to eq '8-11A'
      expect(final_exam_logic['B-W-8:00A'][:exam_slot]).to eq '1'
      expect(final_exam_logic['B-CHEM 1A'][:exam_day]).to eq 'Wednesday'
      expect(final_exam_logic['B-CHEM 1A'][:exam_time]).to eq '8-11A'
      expect(final_exam_logic['B-CHEM 1A'][:exam_slot]).to eq '9'
      expect(final_exam_logic['B-F-7:00P'][:exam_day]).to eq 'Friday'
      expect(final_exam_logic['B-F-7:00P'][:exam_time]).to eq '3-6P'
      expect(final_exam_logic['B-F-7:00P'][:exam_slot]).to eq '19'

      expect(final_exam_logic['D-W-8:00A'][:exam_day]).to eq 'Monday'
      expect(final_exam_logic['D-W-8:00A'][:exam_time]).to eq '7-10P'
      expect(final_exam_logic['D-W-8:00A'][:exam_slot]).to eq '4'
      expect(final_exam_logic['D-FRENCH 2'][:exam_day]).to eq 'Wednesday'
      expect(final_exam_logic['D-FRENCH 2'][:exam_time]).to eq '11:30-2:30P'
      expect(final_exam_logic['D-FRENCH 2'][:exam_slot]).to eq '10'
      expect(final_exam_logic['D-Sa'][:exam_day]).to eq 'Wednesday'
      expect(final_exam_logic['D-Sa'][:exam_time]).to eq '3-6P'
      expect(final_exam_logic['D-Sa'][:exam_slot]).to eq '11'
    end
  end

end
