require 'csv'

module Berkeley
  # Represents temporary final exam 
  class FinalExamSchedule

    def self.get_feed
      self.generate_schedule_hash
    end

    def self.generate_schedule_hash
      course_to_exam = Hash.new
      CSV.foreach("db/fa16-final-exam-schedule.csv",{:headers=>true}) do |row|
        # split each row's output by time and day
        row_output = row["For Class Start Times"].split(" ")
        
        # prepare the map and sets of dates and times
        times = Array.new
        dates = Array.new
        exam = row["Day"] + ", " + row["Date"] + ", " + row["Time"];

        # iterate through every row
        row_output.each do |element|
          # separate the dates and times of each row
          if element.include?(":")
            times << element.tr(',', '') # remove the comma from some of the times
          elsif element.include?("M") or element.include?("TuTh") or element.include?("S")
            dates << element
          # takes care of whenever it says "date after 5pm"
          elsif element == "after"
            times << "5:30pm"
            times << "6:00pm"
            times << "6:30pm"
            times << "7:00pm"
            times << "7:30pm"
          end
        end
        
        # add the dates to the mapping
        if dates != []
          dates.each do |date|
            # stores weekends first
            if date.include?("S")
              # add course and exam mapping
              course_to_exam["S"] = exam

            else
              times.each do |time|
                # add course and exam mapping like M-10:00am => Monday, 12/12/16, 8-11am
                date.split(/(?=[A-Z])/).each do |day|
                  key = day + "-" + time
                  course_to_exam[key] = exam
                end
              end
            end # ends conditional

          end # ends date loop
        end # ends conditional
      end
      course_to_exam
    end

  end
end
