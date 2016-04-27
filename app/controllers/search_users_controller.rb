class SearchUsersController < ApplicationController
  include ViewAsAuthorization
  include User::Parser

  before_action :api_authenticate

  rescue_from ArgumentError, with: :handle_api_exception
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  DEFAULT_LIMIT_SEARCH_RESULTS = 50

  def search_users
    users = authorize_results by_id(id_param)
    render json: { users: decorate(users) }.to_json
  end

  def search_users_by_uid
    users = authorize_results User::SearchUsersByUid.new(id: id_param).search_users_by_uid
    render json: { users: decorate(users) }.to_json
  end

  def by_id_or_name
    opts = {}
    unless can_view_as_for_all_uids? current_user
      require_advisor current_user.real_user_id
      opts[:roles] = [:applicant, :student, :recentStudent]
    end
    id_or_name = params.require 'input'
    # We authorize_results of SearchUsersByName via roles restriction above.
    users = id_or_name =~ /\A\d+\z/ ?
      authorize_results(by_id id_or_name, opts) :
      User::SearchUsersByName.new.search_by(id_or_name, opts)
    render json: { users: decorate(users.take(limit)) }.to_json
  end

  private

  def by_id(id, opts={})
    User::SearchUsers.new(opts.merge id: id).search_users
  end

  def decorate(users)
    unless users.nil? || users.empty?
      if (saved = User::StoredUsers.get(current_user.real_user_id)[:saved])
        stored_uid_list = saved.map { |user| user['ldap_uid'] }
        users.each { |user| user[:saved] = stored_uid_list.include? user[:ldap_uid] }
      end
    end
    users
  end

  def authorize_results(users)
    # Because this returns users object we can chain method calls
    users.each { |user| authorize_user_lookup current_user, user['ldap_uid'] }
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
