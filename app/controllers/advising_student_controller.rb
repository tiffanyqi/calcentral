class AdvisingStudentController < ApplicationController
  include CampusSolutions::StudentLookupFeatureFlagged
  include AdvisorAuthorization

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
      academics: MyAcademics::Merged.new(student_uid).get_feed
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
    authorize_advisor_view_as current_user.real_user_id, student_uid_param
  end

  def student_uid_param
    params.require 'student_uid'
  end

end
