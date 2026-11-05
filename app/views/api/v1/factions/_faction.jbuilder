# frozen_string_literal: true

json.id faction.id
json.slug faction.slug
json.name faction.name
json.alignment faction.alignment
json.area faction.area
json.focus faction.focus
json.logo do
  json.partial! "api/v1/shared/file", record: faction, attr: :logo
end
json.mission_count mission_count
