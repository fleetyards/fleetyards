# frozen_string_literal: true

json.id @feedback.id
json.message @feedback.message
json.feature_name @feedback.feature_name
json.page_path @feedback.page_path
json.created_at @feedback.created_at&.utc&.iso8601
