module CampusSolutions
  class UserSearch < Proxy
    include StudentLookupFeatureFlagged

    attr_accessor :url

    def initialize(options = {})
      raise ArgumentError, 'Arg :name_1 is required in user search' if options[:name_1].blank?
      raise ArgumentError, 'Arg :affiliations is required and must be an array' unless options[:affiliations].is_a? Array
      super options
      params = {
        NAME1: options[:name_1],
        AFFILIATIONS: options[:affiliations]
      }
      params[:NAME2] = options[:name_2] unless options[:name_2].blank?
      @url = "#{@settings.base_url}/UC_CC_USER_LOOKUP.v1/lookup?#{params.to_query}"
    end

    def build_feed(response)
      feed = { users: [] }
      unless (xml = response.parsed_response).blank?
        users = (root = xml['UC_AA_USER_SEARCH']) && (results = root['SEARCH_RESULTS']) && results['USER_DATA']
        users.each do |user|
          feed[:users] << {
            campus_solutions_id: user['CAMPUS_SOLUTION_ID'],
            sid: user['STUDENT_ID'],
            name: user['NAME'],
            academic_programs: transform(user['ACADEMIC_PROGRAMS'])
          }
        end
      end
      feed
    end

    def xml_filename
      'user_search.xml'
    end

    private

    def transform(root)
      feed = []
      if root && (academic_programs = root['ACADEMIC_PROGRAM'])
        academic_programs.each do |program|
          feed << {
            term: program['TERM'],
            career: program['ACAD_CAREER'],
            plan: program['ACAD_PLAN'],
            plan_description: program['ACAD_PLAN_DESCR'],
            program: program['ACAD_PROGRAM'],
            program_description: program['ACAD_PROGRAM_DESCR'],
            college: program['ACAD_COLLEGE']
          }
        end
      end
      feed
    end

  end
end
