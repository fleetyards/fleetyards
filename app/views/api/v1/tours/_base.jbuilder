# frozen_string_literal: true

json.id tour.id
json.title tour.title
json.slug tour.slug
json.description tour.description
json.status tour.status
json.starts_at tour.starts_at&.utc&.iso8601
json.settled_at tour.settled_at&.utc&.iso8601

json.created_by do
  json.id tour.created_by_id
  json.username tour.created_by&.username
end

json.partial! "api/shared/dates", record: tour
