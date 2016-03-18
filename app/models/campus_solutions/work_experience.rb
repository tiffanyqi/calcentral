module CampusSolutions
  class WorkExperience < PostingProxy

    include ProfileFeatureFlagged
    include CampusSolutionsIdRequired

    def initialize(options = {})
      super(Settings.campus_solutions_proxy, options)
      initialize_mocks if @fake
    end

    def self.field_mappings
      @field_mappings ||= FieldMapping.to_hash(
        [
          FieldMapping.required(:sequenceNbr, :SEQ_NO),
          FieldMapping.required(:employmentDescr, :EMPLOYMENT_DESCR),
          FieldMapping.required(:country, :COUNTRY),
          FieldMapping.required(:city, :CITY),
          FieldMapping.required(:state, :STATE),
          FieldMapping.required(:phone, :PHONE),
          FieldMapping.required(:startDt, :START_DT),
          FieldMapping.required(:endDt, :END_DT),
          FieldMapping.required(:titleLong, :TITLE_LONG),
          FieldMapping.required(:employFrac, :EMPLOY_FRAC),
          FieldMapping.required(:hoursPerWeek, :HOURS_PER_WEEK),
          FieldMapping.required(:endingPayRate, :ENDING_PAY_RATE),
          FieldMapping.required(:currencyType, :CURRENCY_CD),
          FieldMapping.required(:payFrequency, :PAY_FREQUENCY)

        ]
      )
    end

    def request_root_xml_node
      'Prior_Work_Exp'
    end

    def response_root_xml_node
      'PriorWork'
    end

    def xml_filename
      'work_experience.xml'
    end

    def url
      "#{@settings.base_url}/UC_CC_PRIOR_WORK_EXP.v1/post/"
    end

  end
end
