class SearchUsersController < ApplicationController
  include ViewAsAuthorization

  def search_users
    authorize_user_lookup current_user, (uid = uid_param)
    users_found = User::SearchUsers.new(id: uid).search_users
    render json: { users: users_found }.to_json
  end

  def search_users_by_uid
    authorize_user_lookup current_user, (uid = uid_param)
    users_found = User::SearchUsersByUid.new(id: uid).search_users_by_uid
    render json: { users: users_found }.to_json
  end

  private

  def uid_param
    params.require 'id'
  end

end
