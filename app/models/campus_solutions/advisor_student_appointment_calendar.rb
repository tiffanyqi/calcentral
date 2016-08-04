module CampusSolutions
  class AdvisorStudentAppointmentCalendar < Proxy
    include CampusSolutionsIdRequired

    def xml_filename
      'advisor_student_appointment_calendar.xml'
    end

    def url
      "#{@settings.base_url}/UC_AA_ADV_APPMT.v1/?EMPLID=#{@campus_solutions_id}"
    end
  end
end
