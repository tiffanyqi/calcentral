module CampusSolutions
  class HigherOneUrlController < CampusSolutionsController
    include AllowDelegateViewAs
    include DisallowAdvisorViewAs
    include DisallowClassicViewAs
    before_filter :authorize_for_financial

    def get
      options = {}
      options[:delegate_uid] = current_user.original_delegate_user_id if current_user.authenticated_as_delegate?
      model = CampusSolutions::MyHigherOneUrl.from_session(session, options)
      render json: model.get_feed_as_json
    end

  end
end
