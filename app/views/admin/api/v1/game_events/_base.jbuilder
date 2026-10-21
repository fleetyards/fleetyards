# frozen_string_literal: true

json.id game_event.id
json.title game_event.title
json.description game_event.description if game_event.description.present?
json.location game_event.location if game_event.location.present?
json.url game_event.url if game_event.url.present?
json.category game_event.category
json.starts_at game_event.starts_at.utc.iso8601
json.ends_at game_event.ends_at.utc.iso8601 if game_event.ends_at.present?
json.published game_event.published

if game_event.cover_image.attached?
  json.cover_image do
    json.partial! "api/v1/shared/file", record: game_event, attr: :cover_image
  end
end

json.partial! "api/shared/dates", record: game_event
