class SearchUsersController < ApplicationController
  include ViewAsAuthorization

  before_action :api_authenticate

  rescue_from ArgumentError, with: :handle_api_exception
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  DEFAULT_LIMIT_SEARCH_RESULTS = 50

  def search_users
    users_found = authorize_results User::SearchUsers.new(id: id_param).search_users
    render json: { users: users_found }.to_json
  end

  def search_users_by_uid
    users_found = authorize_results User::SearchUsersByUid.new(id: id_param).search_users_by_uid
    render json: { users: users_found }.to_json
  end

  def by_id_or_name
    filter = {}
    unless can_view_as_for_all_uids? current_user
      require_advisor current_user.real_user_id
      filter = { roles: [:applicant, :student, :recentStudent] }
    end
    id_or_name = params.require 'input'
    users = id_or_name =~ /\A\d+\z/ ?
      User::SearchUsers.new(id: id_or_name).search_users :
      User::SearchUsersByName.new.search_by(id_or_name, filter)
    render json: { users: users.take(limit) }.to_json
  end

  private

  def authorize_results(users)
    users.each do |user|
      authorize_user_lookup current_user, user['ldap_uid']
    end
  end

  def id_param
    params.require 'id'
  end

  def limit
    return DEFAULT_LIMIT_SEARCH_RESULTS unless (arg = params[:limit])
    raise ArgumentError, "The 'limit' param must be a number greater than zero. Invalid: #{arg}" if (limit = arg.to_i) <= 0
    limit
  end

end
