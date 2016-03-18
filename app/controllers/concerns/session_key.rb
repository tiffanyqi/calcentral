module SessionKey

    VIEW_AS_TYPES = %w(original_user_id original_advisor_user_id original_delegate_user_id)
    CANVAS_MASQUERADE_TYPES = %w(canvas_masquerading_user_id)

    (VIEW_AS_TYPES + CANVAS_MASQUERADE_TYPES).each { |key| define_singleton_method(key) { key } }

end
