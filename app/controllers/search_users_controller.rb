class SearchUsersController < ApplicationController
  include ViewAsAuthorization
  include User::Parser

  before_action :api_authenticate

  rescue_from Errors::BadRequestError, with: :handle_client_error
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  DEFAULT_LIMIT_SEARCH_RESULTS = 50

  def search_users
    users = authorize_results by_id(id_param)
    render json: { users: prepare_to_render(users) }.to_json
  end

  def search_users_by_uid
    results = User::SearchUsersByUid.new(id: id_param).search_users_by_uid
    users = authorize_results add_user_attributes(results)
    render json: { users: prepare_to_render(users) }.to_json
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
    render json: { users: prepare_to_render(users.take(limit)) }.to_json
  end

  private

  def by_id(id, opts={})
    add_user_attributes User::SearchUsers.new(opts.merge id: id).search_users
  end

  def prepare_to_render(users)
    unless users.nil? || users.empty?
      # Give the front-end the camelCase it wants.
      users.map! { |user| HashConverter.camelize user }
      # Identify users in the result-set which were once "saved".
      if (saved_users = User::StoredUsers.get(current_user.real_user_id)[:saved])
        stored_uid_list = saved_users.map { |saved_user| saved_user['ldap_uid'] }
        users.each { |user| user[:saved] = stored_uid_list.include? user[:ldapUid] }
      end
    end
    # If users is a Set then uniqueness is enforced by default
    users.is_a?(Array) ? users.uniq { |user| user[:ldapUid] } : users
  end

  def add_user_attributes(users)
    # We add name information per user. Otherwise, the front-end would only receive identifiers.
    users.map! do |user|
      attributes = User::AggregatedAttributes.new(user['ldap_uid']).get_feed
      user.merge attributes
    end
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
    raise Errors::BadRequestError, "The 'limit' param must be a number greater than zero. Invalid: #{arg}" if (limit = arg.to_i) <= 0
    limit
  end

end
