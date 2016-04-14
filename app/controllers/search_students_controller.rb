class SearchStudentsController < ApplicationController
  include AdvisorAuthorization

  before_action :api_authenticate

  rescue_from ArgumentError, with: :handle_api_exception
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  DEFAULT_LIMIT_SEARCH_RESULTS = 50

  def by_name
    require_advisor current_user.real_user_id
    name = params.require 'name'
    students = User::SearchUsersByName.new.search_by name, { roles: [:applicant, :student, :recentStudent] }
    render json: { students: students.take(limit) }.to_json
  end

  private

  def limit
    return DEFAULT_LIMIT_SEARCH_RESULTS unless (arg = params[:limit])
    raise ArgumentError, "The 'limit' param must be a number greater than zero. Invalid: #{arg}" if (limit = arg.to_i) <= 0
    limit
  end

end
