class MediacastsController < ApplicationController

  before_filter :api_authenticate

  def initialize(options = {})
    @options = options
  end

  # GET /api/media/:term_yr/:term_cd/:dept_name/:catalog_id
  def get_media
    term_yr = params.require 'term_yr'
    term_cd = params.require 'term_cd'
    dept_name = params.require 'dept_name'
    catalog_id = params.require 'catalog_id'
    uid = session['user_id']

    policy = policy Berkeley::Course.new @options
    ccn_list = ccn_list(term_yr, term_cd, dept_name, catalog_id)
    proxy = Webcast::Merged.new uid, policy, term_yr, term_cd, ccn_list, @options
    render :json => proxy.get_feed
  end

  private

  def ccn_list(term_yr, term_cd, dept_name, catalog_id)
    legacy = Berkeley::Terms.legacy? term_yr, term_cd
    sections = legacy ?
      CampusOracle::Queries.get_all_course_sections(term_yr, term_cd, dept_name, catalog_id) :
      EdoOracle::Queries.get_all_course_sections(term_id(term_yr, term_cd), dept_name, catalog_id)
    key = legacy ? 'course_cntl_num' : 'section_id'
    sections.map { |section| section[key].to_i }
  end

  def term_id(term_yr, term_cd)
    Berkeley::TermCodes.to_edo_id term_yr, term_cd
  end

end
