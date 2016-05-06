module SessionKey

    VIEW_AS_TYPES = %w(original_user_id original_advisor_user_id original_delegate_user_id)
    CANVAS_MASQUERADE_TYPES = %w(canvas_masquerading_user_id)
    ALL_KEYS = %w(user_id lti_authenticated_only canvas_user_id canvas_course_id) + SessionKey::CANVAS_MASQUERADE_TYPES + SessionKey::VIEW_AS_TYPES

    ALL_KEYS.each { |key| define_singleton_method(key) { key } }

end
