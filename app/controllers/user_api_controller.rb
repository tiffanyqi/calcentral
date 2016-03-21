class UserApiController < ApplicationController
  extend Cache::Cacheable
  include DelegateAccessible

  def self.expire(id = nil)
    # no-op; this class uses the cache only to reduce the number of writes to User::Visit. We want to just expire
    # with time, not when the cache is forcibly cleared.
  end

  def am_i_logged_in
    response.headers['Cache-Control'] = 'no-cache, no-store, private, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '-1'
    render :json => {
      :amILoggedIn => !!session['user_id']
    }.to_json
  end

  def mystatus
    ActiveRecordHelper.clear_stale_connections
    status = {}
    features = HashConverter.camelize Settings.features.marshal_dump

    if (user_id = session['user_id'])
      # wrap User::Visit.record_session inside a cache lookup so that we have to write User::Visit records less often.
      directly_authenticated = current_user.directly_authenticated?
      self.class.fetch_from_cache(Cache::KeyGenerator.per_view_as_type user_id, session) do
        User::Visit.record user_id if directly_authenticated
        true
      end
      advisor_acting_as_uid = !directly_authenticated && current_user.original_advisor_user_id
      delegate_acting_as_uid = !directly_authenticated && current_user.original_delegate_user_id
      status.merge!({
        :isBasicAuthEnabled => Settings.developer_auth.enabled,
        :isLoggedIn => true,
        :features => features,
        :actingAsUid => directly_authenticated || advisor_acting_as_uid || delegate_acting_as_uid ? false : current_user.real_user_id,
        :advisorActingAsUid => advisor_acting_as_uid,
        :delegateActingAsUid => delegate_acting_as_uid,
        :youtubeSplashId => Settings.youtube_splash_id
      })
      status.merge! User::Api.from_session(session).get_feed
    else
      status.merge!({
        :isBasicAuthEnabled => Settings.developer_auth.enabled,
        :isLoggedIn => false,
        :features => features,
        :youtubeSplashId => Settings.youtube_splash_id
      })
    end
    render :json => status.to_json
  end

  def record_first_login
    User::Api.from_session(session).record_first_login if current_user.directly_authenticated?
    render :nothing => true, :status => 204
  end

  def delete
    if (user_id = session['user_id']) && current_user.directly_authenticated?
      User::Api.delete user_id
      render :nothing => true, :status => 204
    else
      render :nothing => true, :status => 403
    end
  end

  def calendar_opt_in
    expire_current_user
    if (user_id = session['user_id']) && current_user.directly_authenticated?
      Calendar::User.where(uid: user_id).first_or_create
      render :nothing => true, :status => 204
    else
      render :nothing => true, :status => 403
    end
  end

  def calendar_opt_out
    expire_current_user
    if (user_id = session['user_id']) && current_user.directly_authenticated?
      Calendar::User.where(uid: user_id).delete_all
      render :nothing => true, :status => 204
    else
      render :nothing => true, :status => 403
    end
  end

end
