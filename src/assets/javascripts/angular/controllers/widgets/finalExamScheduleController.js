'use strict';

var angular = require('angular');

/**
 * Final exam schedule controller
 */
angular.module('calcentral.controllers').controller('FinalExamScheduleController', function(apiService, academicsService, myClassesFactory, $scope) {

    // ref: http://stackoverflow.com/a/1293163/2343
    // This will parse a delimited string into an array of
    // arrays. The default delimiter is the comma, but this
    // can be overriden in the second argument.
    function CSVToArray( strData, strDelimiter ){
        // Check to see if the delimiter is defined. If not,
        // then default to comma.
        strDelimiter = (strDelimiter || ",");

        // Create a regular expression to parse the CSV values.
        var objPattern = new RegExp(
            (
                // Delimiters.
                "(\\" + strDelimiter + "|\\r?\\n|\\r|^)" +

                // Quoted fields.
                "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +

                // Standard fields.
                "([^\"\\" + strDelimiter + "\\r\\n]*))"
            ),
            "gi"
            );


        // Create an array to hold our data. Give the array
        // a default empty first row.
        var arrData = [[]];

        // Create an array to hold our individual pattern
        // matching groups.
        var arrMatches = null;


        // Keep looping over the regular expression matches
        // until we can no longer find a match.
        while (arrMatches = objPattern.exec( strData )){

            // Get the delimiter that was found.
            var strMatchedDelimiter = arrMatches[ 1 ];

            // Check to see if the given delimiter has a length
            // (is not the start of string) and if it matches
            // field delimiter. If id does not, then we know
            // that this delimiter is a row delimiter.
            if (
                strMatchedDelimiter.length &&
                strMatchedDelimiter !== strDelimiter
                ){

                // Since we have reached a new row of data,
                // add an empty row to our data array.
                arrData.push( [] );

            }

            var strMatchedValue;

            // Now that we have our delimiter out of the way,
            // let's check to see which kind of value we
            // captured (quoted or unquoted).
            if (arrMatches[ 2 ]){

                // We found a quoted value. When we capture
                // this value, unescape any double quotes.
                strMatchedValue = arrMatches[ 2 ].replace(
                    new RegExp( "\"\"", "g" ),
                    "\""
                    );

            } else {

                // We found a non-quoted value.
                strMatchedValue = arrMatches[ 3 ];

            }


            // Now that we have our value string, let's add
            // it to the data array.
            arrData[ arrData.length - 1 ].push( strMatchedValue );
        }

        // Return the parsed data.
        return( arrData );
    }



  var getMyClasses = function(options) {
    myClassesFactory.getClasses(options).then(function(data) {
      if (_.get(data, 'feedName')) {
        apiService.updatedFeeds.feedLoaded(data);
        bindScopes(data.classes);
      }
      angular.extend($scope, data);
    });
  };

  var schedule = CSVtoArray('../../../../../db/fa16-final-exam-schedule.csv');
  // src/assets/javascripts/controllers/widgets/FinalExamScheduleController
  // db/fa-16-final-exam-schedule.csv

  $scope.schedule = schedule;

  // function createCourseTimeToExam(csv) {
  //   var courseTimeToExam = new Object();
  //   for (int row; row < csv.length; row++) {

  //   }
  // }

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




  var getMyExams = function(options) {

  }

  var foreignLanguages = []
  // chem1a, chem 1b, econ1, econ 100b

  

});
