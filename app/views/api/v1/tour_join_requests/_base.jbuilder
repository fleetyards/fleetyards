# frozen_string_literal: true

json.id tour_join_request.id
json.tour_id tour_join_request.tour_id
json.status tour_join_request.aasm_state

json.user do
  json.id tour_join_request.user_id
  json.username tour_join_request.user&.username

  if tour_join_request.user&.avatar&.attached?
    json.avatar do
      json.partial! "api/v1/shared/file", record: tour_join_request.user, attr: :avatar
    end
  end
end

if tour_join_request.decided_by.present?
  json.decided_by do
    json.id tour_join_request.decided_by_id
    json.username tour_join_request.decided_by.username
  end
end

json.decided_at tour_join_request.decided_at&.utc&.iso8601

json.partial! "api/shared/dates", record: tour_join_request
