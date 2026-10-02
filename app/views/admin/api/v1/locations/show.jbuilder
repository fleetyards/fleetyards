# frozen_string_literal: true

json.partial! "admin/api/v1/locations/base", location: @location

json.description @location.description

json.partial! "api/v1/locations/appearance", location: @location, curated: true

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

json.shops @location.shops.with_attached_image.order(:name) do |shop|
  json.id shop.id
  json.name shop.name
  json.has_image shop.image.attached?
end

json.terminals @location.terminals.sort_by(&:name) do |terminal|
  json.id terminal.id
  json.name terminal.name
  json.available terminal.available
end
