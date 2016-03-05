module CampusSolutions
  class HigherOneUrlController < CampusSolutionsController

    def get
      model = CampusSolutions::MyHigherOneUrl.from_session proxy_args
      render json: model.get_feed_as_json
    end

    private

    def proxy_args
      delegate_uid = session[SessionKey.original_delegate_user_id]
      delegate_uid ? session.merge(delegate_uid: delegate_uid) : session
    end

  end
end

