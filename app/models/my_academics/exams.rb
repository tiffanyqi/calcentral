module MyAcademics
  class Exams
    include AcademicsModule
    include ClassLogger
    include DatedFeed
    include User::Student
    include FinalExamsFeatureFlagged

    # Merges the final result into the academics feed
    def merge(data = {})
      if is_feature_enabled && (academics_data = parse_academic_data data[:semesters])
        assign_exams academics_data
        # Sort by semester, current first
        data[:examSchedule] = academics_data.sort_by { |semester| semester[:timeBucket] == 'current' ? 0 : 1 }
      end
    end

    # Parses the my academics semesters feed, and prepares data to be populated
    def parse_academic_data(data)
      final_exam_schedule = []

      # select correct semesters
      data.reject{|x| x[:termCode] == 'C' || x[:timeBucket] == 'past'}.each do |semester|
        courses = []
        cs_data_available = determine_cs_data_available(semester)
        parse_courses(semester, courses, cs_data_available)
        final_exam_schedule << {
          cs_data_available: cs_data_available,
          name: semester[:name],
          term: semester[:termCode],
          term_year: semester[:termYear],
          courses: courses,
          timeBucket: semester[:timeBucket],
          slug: semester[:slug]
        }
      end
      final_exam_schedule
    end

    # Takes semester data and add fields to courses to make it easier to read
    def parse_courses(semester, courses, cs_data_available)
      semester[:classes].each do |course|
        course[:sections].select{|x| course[:role] == 'Student' && x[:is_primary_section]}.each do |section|
          parsed_course = {
            name: course[:course_code],
            number: course[:courseCatalog].gsub(/[^0-9]/, '').to_i,
            time: section[:schedules][:recurring].to_a.first.try(:[], :schedule),
            waitlisted: section[:waitlisted]
          }
          if cs_data_available
            if section[:final_exams].any?
              exam = section[:final_exams].first
              parsed_course[:exam_location] = choose_cs_exam_location(exam)
              parsed_course[:exam_date] = parse_cs_exam_date(exam)
              parsed_course[:exam_time] = parse_cs_exam_time(exam)
              parsed_course[:exam_slot] = parse_cs_exam_slot(exam)
            else
              parsed_course[:exam_slot] = 'none'
              parsed_course[:exam_location] = 'No exam.'
            end
          end
          courses << parsed_course
        end
      end
    end

    # Assigns exams to academics_data if there is no cs data available based on conversion table
    def assign_exams(academics_data)
      if (final_exam_schedule = Berkeley::FinalExamSchedule.fetch)
        academics_data.each do |semester|
          semester[:courses].each do |course|
            unless semester[:cs_data_available]
              if (exam_key = determine_exam_key(semester, course, final_exam_schedule))
                if (exam = final_exam_schedule[exam_key])
                  course[:exam_location] = '' # not assigned a location yet
                  course[:exam_time] = exam[:exam_time]
                  course[:exam_slot] = exam[:exam_slot].to_i
                  course[:exam_date] = determine_exam_date(semester, exam[:exam_day])
                end
              end
            end
          end
          sort_exams semester
        end
      end
    end

    def sort_exams(semester)
      semester[:exams] = semester[:courses].reject { |course| course[:exam_slot].nil? }
      if semester[:cs_data_available]
        # brings none exam_slots to the bottom
        semester[:exams] = semester[:courses].sort do |a,b|
          if a[:exam_slot] == 'none'
            1
          elsif b[:exam_slot] == 'none'
            -1
          else
            a[:exam_slot] <=> b[:exam_slot]
          end
        end
      else # interim
        semester[:exams].sort! { |a,b| a[:exam_slot] <=> b[:exam_slot] }
      end
      semester[:exams] = semester[:exams].group_by { |course| course[:exam_slot] }
    end

    ## Support Functions

    # Determine whether CS data is available depending on where we are in the semester
    def determine_cs_data_available(semester)
      term = Berkeley::Terms.fetch.campus[semester[:slug]]
      # Still calculated by whether or not we are 8 weeks before the end of the term or not. (Adjust later)
      current_date = Settings.terms.fake_now || Time.now
      term.final_exam_cs_data_available < current_date
    end

    # Takes the exam date and makes it presentable, Mon 12/12
    def parse_cs_exam_date(exam)
      date = exam[:exam_date]
      date && date.strftime('%a %m/%-d')
    end

    # Takes the exam time and makes it presentable, 07:00PM-10:00PM
    def parse_cs_exam_time(exam)
      start = exam[:exam_start_time]
      ending = exam[:exam_end_time]
      start && ending && "#{start.strftime '%I:%M%p'}-#{ending.strftime '%I:%M%p'}"
    end

    # Takes exam information and makes it usable
    def parse_cs_exam_slot(exam)
      time = exam[:exam_start_time]
      date = exam[:exam_date]
      if time && date
        Time.parse("#{date.strftime '%y-%m-%d'} #{time.strftime '%H:%M'}")
      elsif date
        Time.parse(date.strftime '%y-%m-%d')
      else
        'none'
      end
    end

    def choose_cs_exam_location(exam)
      if exam[:location]
        exam[:location]
      elsif exam[:exam_type] == 'A'
        'Final exam information not available. Please consult instructors.'
      else
        'Location TBD'
      end
    end

    # Determines what the exam key would be when parsing final exam conversion
    def determine_exam_key(semester, course, final_exam_schedule)
      # if the course has its own time, use that
      term = semester[:term]
      key_by_name = "#{term}-#{course[:name]}"
      if final_exam_schedule[key_by_name]
        key_by_name

      # otherwise it's a undergrad course, so check its time
      elsif course[:time] && course[:number] < 200
        course_schedule = course[:time].split(' ')
        course_days = course_schedule[0]
        course_times = course_schedule[1]

        # start to create the key, takes into account courses with two meeting patterns
        # If the course is MTuTh, TuTh should be the dominant meeting pattern, so return 'Tu'
        day = (course_days.include?('MTuTh') ? 'Tu' : course_days.split(/(?=[A-Z])/)[0]) # first letter for day
        start_time = course_times.split('-')[0] # take the first time for the time

        (day == 'Sa' || day == 'Su') ? "#{term}-#{day}" : "#{term}-#{day}-#{start_time}"
      else
        nil
      end
    end

    # Determines what the exam date would be for interim
    def determine_exam_date(semester, day)
      return nil unless semester && day && (term = Berkeley::Terms.fetch.campus[semester[:slug]])
      # select first day and add days to output exam date format
      first_day = term.final_exam_week_start
      month = first_day.month
      # add numbers to the date depending on what day it is
      date = first_day.day
      case day
        when 'Tuesday'
          date += 1
        when 'Wednesday'
          date += 2
        when 'Thursday'
          date += 3
        when 'Friday'
          date += 4
        else
          date += 0
      end
      # Return, for example, Mon 5/10
      "#{day[0...3]} #{month}/#{date}"
    end

  end
end
