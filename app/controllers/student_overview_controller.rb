class StudentOverviewController < ApplicationController
  include ClassLogger

  before_action :api_authenticate
  before_action :authorize_access_to_student

  rescue_from StandardError, with: :handle_api_exception
  rescue_from Errors::ClientError, with: :handle_client_error
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def authorize_access_to_student
    authorize current_user, :can_view_as_for_all_uids?
  end

  def student
    student_uid = params.require 'student_uid'
    person = User::AggregatedAttributes.new(student_uid).get_feed
    unless person[:roles][:student] || person[:roles][:exStudent] || person[:roles][:applicant]
      raise Pundit::NotAuthorizedError.new "#{current_user.user_id} is forbidden to view #{student_uid} because #{student_uid} is neither student, ex-student nor applicant"
    end
    render json: person
  end

end
