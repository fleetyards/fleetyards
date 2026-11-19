# frozen_string_literal: true

json.id feedback.id
json.message feedback.message
json.feature_name feedback.feature_name
json.page_path feedback.page_path
json.state feedback.aasm_state
json.user_id feedback.user_id
json.username feedback.user&.username
json.resolved_at feedback.resolved_at&.utc&.iso8601
json.resolved_by_name feedback.resolved_by&.username
json.replies_count feedback.replies_count
json.partial! "api/shared/dates", record: feedback
