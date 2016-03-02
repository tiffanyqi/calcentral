class UserSpecificModel
  include ActiveAttrModel
  include ClassLogger
  attr_reader :authentication_state

  def self.from_session(session_state)
    view_as_related = Hash[SessionKey::VIEW_AS_TYPES.collect { |k| [k, session_state[k]] }]
    filtered_session = {'lti_authenticated_only' => session_state['lti_authenticated_only'] }.merge view_as_related
    self.new(session_state['user_id'], filtered_session)
  end

  def initialize(uid, options={})
    @uid = uid
    @options = options
    @authentication_state = AuthenticationState.new @options.merge('user_id' => @uid)
  end

  def instance_key
    @uid
  end

  def directly_authenticated?
    @authentication_state.directly_authenticated?
  end

end
