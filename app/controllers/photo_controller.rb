class PhotoController < ApplicationController

  before_filter :api_authenticate_401

  def my_photo
    if (photo_feed = User::Photo.fetch session['user_id'], session)
      data = photo_feed[:photo]
      send_data(
        data,
        type: 'image/jpeg',
        disposition: 'inline'
      )
    else
      render :nothing => true, :status => 200
    end
  end

end
