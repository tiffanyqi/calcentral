class AdvisingStudentController < ApplicationController
  include CampusSolutions::StudentLookupFeatureFlagged

  before_action :api_authenticate
  before_action :authorize_student_lookup

  rescue_from StandardError, with: :handle_api_exception
  rescue_from Errors::ClientError, with: :handle_client_error
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def profile
    student_uid = student_uid_param
    render json: {
      attributes: @attributes,
      contacts: HubEdos::Contacts.new(user_id: student_uid, include_fields: %w(names addresses phones emails)).get
    }
  end

  def academics
    student_uid = student_uid_param
    render json: {
      academics: MyAcademics::Merged.new(student_uid).get_feed,
      examSchedule: MyAcademics::Exams.new(student_uid).merge
    }
  end

  def enrollment_term
    model = CampusSolutions::MyEnrollmentTerm.new student_uid_param
    model.term_id = params['term_id']
    render json: model.get_feed_as_json
  end

  def enrollment_terms
    render json: CampusSolutions::MyEnrollmentTerms.new(student_uid_param).get_feed_as_json
  end

  def academic_plan
    model = CampusSolutions::MyAcademicPlan.new student_uid_param
    model.term_id = params['term_id']
    render json: model.get_feed_as_json
  end

  def resources
    json = CampusSolutions::AdvisingResources.new(user_id: session['user_id'], student_uid: student_uid_param).get
    # Advisors get only a subset of links
    subset = [:ucServiceIndicator, :ucStudentAdvisor]
    if json[:feed] && json[:feed][:ucAdvisingResources] && (links = json[:feed][:ucAdvisingResources][:ucAdvisingLinks])
      filtered_links = links.select { |key| subset.include? key }
      json[:feed][:ucAdvisingResources][:ucAdvisingLinks] = filtered_links
    end
    render json: json
  end

  private

  def authorize_student_lookup
    raise NotAuthorizedError.new('The student lookup feature is disabled') unless is_feature_enabled
    authorize current_user, :can_view_as_for_all_uids?
    @attributes = User::AggregatedAttributes.new(student_uid = student_uid_param).get_feed
    unless @attributes[:roles][:student] || @attributes[:roles][:exStudent] || @attributes[:roles][:applicant]
      raise Pundit::NotAuthorizedError.new "#{current_user.user_id} is forbidden to view #{student_uid} because #{student_uid} is neither student, ex-student nor applicant"
    end
  end

  def student_uid_param
    params.require 'student_uid'
  end

end
