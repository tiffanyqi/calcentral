class PhotoController < ApplicationController

  before_filter :api_authenticate_401

  def my_photo
    unless current_user.authenticated_as_delegate?
      photo_row = User::Photo.fetch(session['user_id'])
    end
    if photo_row
      data = photo_row['photo']
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
