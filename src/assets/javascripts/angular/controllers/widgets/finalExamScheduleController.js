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

  convertCSV('../../../../../db/fa16-final-exam-schedule.csv');
  // src/assets/javascripts/controllers/widgets/FinalExamScheduleController
  // db/fa-16-final-exam-schedule.csv

  /*
   * Create hashes that represent course to exam logic
   */
  var createCourseTimeToExam = function(data) {
  //   var courseTimeToExam = new Object();
  //   for (int row; row < data.length; row++) {

  //   }
  };

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

  };

  loadExamData();



// # parses the final exam schedule: http://schedule.berkeley.edu/examf.html
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
