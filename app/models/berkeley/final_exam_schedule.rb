module Berkeley
  class FinalExamSchedule
    extend Cache::Cacheable
    # Support class for my_academics/exams.rb

    # Takes the final exam csvs and outputs a reasonable format for exams.rb to parse
    def self.fetch
      fetch_from_cache do
        semesters_csv =  {
          B: 'public/csv/sp_final_exam_schedule.csv', # http://schedule.berkeley.edu/examsp.html
          D: 'public/csv/fa_final_exam_schedule.csv' # http://schedule.berkeley.edu/examsf.html
        }
        course_to_exam = Hash.new

        semesters_csv.each do |semester, semester_csv|
          process_semester(semester, semester_csv, course_to_exam)
        end
        course_to_exam
      end
    end

    # processes each semester from the CSV, assigning each key to the hash.
    def self.process_semester(semester, csv, course_to_exam)
      CSV.foreach(csv,{:headers=>true}) do |row|
        exam = {
          exam_day: row['Day'],
          exam_time: row['Time'],
          exam_slot: row['Exam Group']
        }
        times, days, courses = row['Class Times'], row['Class Days'], row['Course Exceptions']

        # add the days to the mapping, e.g key: B-M-10:00A
        sem = semester.to_s
        if days
          days.split(/(?=[A-Z])/).each do |day|
            # for each day and time, create a key from the semester code, day, and time, e.g B-M-8:00A
            times.split(' ').each {|time| course_to_exam[sem + '-' + day + '-' + time] = exam} if times
            course_to_exam[sem + '-' + day] = exam if !times # weekends
          end
        end
        # creates a key from the course code, e.g B-CHEM 1A
        courses.split(', ').each { |course| course_to_exam[sem + '-' + course] = exam } if courses
      end
    end

  end
end
