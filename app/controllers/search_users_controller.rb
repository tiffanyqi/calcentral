class SearchUsersController < ApplicationController
  include ViewAsAuthorization

  def search_users
    users_found = authorize_results User::SearchUsers.new(id: id_param).search_users
    render json: { users: users_found }.to_json
  end

  def search_users_by_uid
    users_found = authorize_results User::SearchUsersByUid.new(id: id_param).search_users_by_uid
    render json: { users: users_found }.to_json
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

end
