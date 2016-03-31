class StudentOverviewController < ApplicationController
  include CampusSolutions::StudentLookupFeatureFlagged

  before_action :api_authenticate
  before_action :authorize_student_lookup

  rescue_from StandardError, with: :handle_api_exception
  rescue_from Errors::ClientError, with: :handle_client_error
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def academics
    student_uid = student_uid_param
    render json: {
      attributes: @attributes,
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
