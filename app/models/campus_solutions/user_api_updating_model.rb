module CampusSolutions
  module UserApiUpdatingModel
    def passthrough(model_name, params)
      proxy = model_name.new({user_id: @uid, params: params})
      result = proxy.get
      PersonDataExpiry.expire @uid
      UserApiExpiry.expire @uid
      result
    end
  end
end
