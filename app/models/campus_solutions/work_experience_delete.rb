module CampusSolutions
  class WorkExperienceDelete < DeletingProxy

    include ProfileFeatureFlagged
    include CampusSolutionsIdRequired

    def initialize(options = {})
      super(Settings.campus_solutions_proxy, options)
      initialize_mocks if @fake
    end

    def self.field_mappings
      @field_mappings ||= FieldMapping.to_hash(
        [
          FieldMapping.required(:sequenceNbr, :SEQUENCE_NBR)
        ]
      )
    end

    def xml_filename
      'prior_work_delete.xml'
    end

    def response_root_xml_node
      'PRIOR_WORK_DELETE_RESPONSE'
    end

    def url
      "#{@settings.base_url}/UC_CC_PRIOR_WORK.v1/priorwork/delete"
    end

  end
end
