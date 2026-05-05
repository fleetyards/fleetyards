# frozen_string_literal: true

json.id mission.id
json.title mission.title
json.slug mission.slug
json.description mission.description
json.category mission.category
json.scenario mission.scenario
json.cover_image_preset mission.cover_image_preset
json.archived mission.archived?
json.archived_at mission.archived_at

if mission.cover_image.attached?
  json.cover_image do
    json.partial! "api/v1/shared/file", record: mission, attr: :cover_image
  end
else
  json.cover_image nil
end

if mission.created_by.present?
  json.created_by do
    json.id mission.created_by.id
    json.username mission.created_by.username
  end
else
  json.created_by nil
end

json.team_count mission.mission_teams.size
json.ship_count mission.mission_ships.count

json.partial! "api/shared/dates", record: mission
