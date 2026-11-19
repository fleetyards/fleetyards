# frozen_string_literal: true

json.id feedback.id
json.message feedback.message
json.feature_name feedback.feature_name
json.page_path feedback.page_path
json.state feedback.aasm_state
json.replies_count feedback.replies.size
json.created_at feedback.created_at&.utc&.iso8601
json.updated_at feedback.updated_at&.utc&.iso8601
