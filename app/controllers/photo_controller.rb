class PhotoController < ApplicationController
  before_filter :api_authenticate_401

  def my_photo
    send_photo get_photo(session['user_id'])
  end

  def photo
    if current_user.policy.can_view_other_user_photo?
      send_photo get_photo(uid_param)
    else
      render :nothing => true, :status => 403
    end
  end

  def get_photo(uid)
    photo_feed = User::Photo.fetch uid, session
    photo_feed.try(:[], :photo)
  end

  def send_photo(data)
    if data
      send_data(
        data,
        type: 'image/jpeg',
        disposition: 'inline'
      )
    else
      render :nothing => true, :status => 200
    end
  end

  def uid_param
    params.require 'uid'
  end

end
