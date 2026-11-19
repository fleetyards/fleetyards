# frozen_string_literal: true

json.partial! "api/v1/feedbacks/feedback", feedback: @feedback
json.replies do
  json.array! @feedback.replies do |reply|
    json.id reply.id
    json.body reply.body
    json.from_admin reply.from_admin
    json.created_at reply.created_at&.utc&.iso8601
  end
end
