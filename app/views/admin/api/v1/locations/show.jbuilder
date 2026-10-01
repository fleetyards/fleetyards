# frozen_string_literal: true

json.partial! "admin/api/v1/locations/base", location: @location

json.description @location.description

if @location.map_parent
  json.map_parent do
    json.partial! "api/v1/locations/link", location: @location.map_parent
  end
else
  json.map_parent nil
end

if @location.system
  json.system do
    json.partial! "api/v1/locations/link", location: @location.system
  end
else
  json.system nil
end

json.children_count @location.children.count
json.game_missions_count @location.game_missions.count
json.mission_template_refs @location.mission_template_refs

json.terminals @location.terminals.sort_by(&:name) do |terminal|
  json.id terminal.id
  json.name terminal.name
  json.available terminal.available
end
