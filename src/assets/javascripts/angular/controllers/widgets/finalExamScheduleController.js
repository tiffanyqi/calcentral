'use strict';

var angular = require('angular');

/**
 * Final exam schedule controller
 */
angular.module('calcentral.controllers').controller('FinalExamScheduleController', function(apiService, enrollmentFactory, $scope) {


  /*
   * Convert the CSV to a string used for the Fall 2016 semester.
   */
  var convertCSV = function(csv) {
    var reader = new FileReader();
    reader.onload = function(progressEvent){
      console.log(this.result);
      var lines = this.result.split('\n');
      for(var line = 0; line < lines.length; line++){
        console.log(lines[line]);
      }
    };
    reader.readAsText(csv);
  };

  // convertCSV('/../../../../db/fa-16-final-exam-schedule.csv')

  // csv to string ideal output
  var data = 'Exam Group,Day,Date,Time,For Class Start Times\n1,Monday,12/12/16,8-11am,MWF 10:00am & 10:30am\n2,Monday,12/12/16,11:30-2:30pm,MWF 11:00am & 11:30am\n3,Monday,12/12/16,3-6pm,Chemistry1A Chemistry1B\n4,Monday,12/12/16,7-10pm,MWF 8:00am & 8:30am\n5,Tuesday,12/13/16,8-11am,TuTh 2:00pm & 2:30pm\n6,Tuesday,12/13/16,11:30-2:30pm,Economics1 Economics100B\n7,Tuesday,12/13/16,3-6pm,TuTh 9:00am & 9:30am\n8,Tuesday,12/13/16,7-10pm,MWF 3:00pm & 3:30pm\n9,Wednesday,12/14/16,8-11am,TuTh 11:00am & 11:30am\n10,Wednesday,12/14/16,11:30-2:30pm,Foreign Languages\n11,Wednesday,12/14/16,3-6pm,"TuTh 8:00am & 8:30am, Saturdays & Sundays"\n12,Wednesday,12/14/16,7-10pm,MWF 1:00pm & 1:30pm\n13,Thursday,12/15/16,8-11am,MWF 4:00pm & 4:30pm\n14,Thursday,12/15/16,11:30-2:30pm,TuTh after 5:00pm\n15,Thursday,12/15/16,3-6pm,MWF 2:00pm & 2:30pm\n16,Thursday,12/15/16,7-10pm,MWF 9:00am & 9:30am\n17,Friday,12/16/16,8-11am,"TuTh 12:00pm, 12:30pm, 1:00pm & 1:30pm"\n18,Friday,12/16/16,11:30-2:30pm,MWF 12:00pm & 12:30pm\n19,Friday,12/16/16,3-6pm,"TuTh 10:00am & 10:30am"\n19,Friday,12/16/16,3-6pm,"MWF after 5:00pm"\n20,Friday,12/16/16,7-10pm,"TuTh 3:00pm, 3:30pm, 4:00pm & 4:30pm"';

  /*
   * Create hashes that represent course to exam logic
   * In accordance with: http://schedule.berkeley.edu/examf.html
   */
  var courseTimeToExam = { };
  var examToTime = { };
  var populateCourseTimeToExam = function(data) {
    var rows = data.split("\n");
    
    for (var i = 1; i < rows.length; i++) {
      var items = rows[i].split(",");
      var examSlot = items[0];
      var examDay = items[1];
      var examDate = items[2];
      var examTime = items[3];
      var classTimes = items[4].split(",");

      // populates examToTime with slot to exam time
      var examTime = examDay + ", " + examDate;
      examToTime[examSlot] = examTime;

      // populate courseTimeToExam
      var times = new Array();
      var dates = new Array();

      for (var j = 0; j < classTimes.length; j++) {
        var time = classTimes[j];
        if (time.includes(":")) {
          times.push(time); // replace the comma too
        } else if (time.includes("M") || time.includes("TuTh") || time.includes("S") ) {
          dates.push(time);
        } else if (time === "after") {
          times.push("5:30pm");
          times.push("6:00pm");
          times.push("6:30pm");
          times.push("7:00pm");
          times.push("7:30pm");
        }
      }
    };
    console.log(examToTime);
  };

// @course_time_to_exam = Hash.new
// CSV.foreach("db/exam_schedule.csv",{:headers=>true}) do |row|
//   # split each row's output by time and day
//   row_output = row["For Class Start Times"].split(" ")
  
//   # prepare the map and sets of dates and times
//   times = Array.new
//   courses = Array.new
//   dates = Array.new

//   # iterate through every row
//   row_output.each do |element|
//     # separate the dates and times of each row
//     if element.include?(":")
//       times << element.tr(',', '') # remove the comma from some of the times
//     elsif element.include?("M") or element.include?("TuTh") or element.include?("S")
//       dates << element
//     # takes care of whenever it says "date after 5pm"
//     elsif element == "after"
//       times << "5:30pm"
//       times << "6:00pm"
//       times << "6:30pm"
//       times << "7:00pm"
//       times << "7:30pm"
//     # everything else is a course
//     elsif element != "&"
//       courses << element
//     end
//   end
  
//   # add the dates to the mapping
//   if dates != []
//     dates.each do |date|
//       # stores weekends first
//       if date.include?("S")
//         # add course and exam mapping
//         @course_time_to_exam["S"] = row["Exam Group"]

//       else
//         times.each do |time|
//           # add course and exam mapping like M-10:00am => 1
//           date.split(/(?=[A-Z])/).each do |day|
//             key = day + "-" + time
//             @course_time_to_exam[key] = row["Exam Group"]
//           end
//         end
//       end # ends conditional

//     end # ends date loop
//   end # ends conditional
// end


  /*
   * Assign exam slots to courses
   */
  var assignExams = function() {

  };

  /*
   * Courses that belong to slot 10 (elementary and intermediate)
   * http://blc.berkeley.edu/languages/?sort=department_name
   * https://docs.google.com/spreadsheets/d/1VIbR_1J44mCeVhnv-fFb8yLB3PhSOzIH45fwVHDde6k/edit#gid=0
   */
  var foreignLanguages = [];
  var chem = ["CHEM 1A", "CHEM 1B"]; // courses for slot 3
  var econ = ["ECON 1", "ECON 100B"]; // courses for slot 6

  /*
   * Load exam data
   */
  var loadExamData = function() {
    $scope.schedule = populateCourseTimeToExam(data);
  };

  loadExamData();


// # determines the final exam slot with a given course
// Course.all.each do |course|
//   # based on whether the course's value is true
//   if course.foreign_language
//     course.exam_number = "10"
//   elsif course.chem1A_1B
//     course.exam_number = "3"
//   elsif course.econ1_100B
//     course.exam_number = "6"
//   # else, go by the time
//   else
//     if course.start_days != nil
//       time = course.start_times
//       day = course.start_days.split(/(?=[A-Z])/)[0]
//       key = day + "-" + time
//       course.exam_number = @course_time_to_exam[key]
//     end
//   end
//   course.save
// end
  

});
