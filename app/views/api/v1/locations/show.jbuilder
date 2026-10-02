# frozen_string_literal: true

json.partial! "api/v1/locations/base", location: @location

json.description @location.description

json.partial! "api/v1/locations/appearance", location: @location

# What can be mined, harvested or hunted there, by kind, as the description
# listed it. An item names its commodity where the catalogue has one.
json.resources Array.wrap(@location.resources) do |group|
  json.kind group["kind"]
  json.items Array.wrap(group["items"]) do |item|
    json.name item["name"]
    json.note item["note"]

    commodity = @commodities[item["name"].to_s.downcase]
    if commodity
      json.commodity do
        json.name commodity.name
        json.slug commodity.slug
      end
    else
      json.commodity nil
    end
  end
end

# From the system down to the parent, for the breadcrumb.
json.ancestors @ancestors do |ancestor|
  json.partial! "api/v1/locations/link", location: ancestor
end

# The game's own parent, where the map draws the place somewhere other than
# where it is.
if @location.map_parent
  json.map_parent do
    json.partial! "api/v1/locations/link", location: @location.map_parent
  end
else
  json.map_parent nil
end

json.children_count @children_count

# Every place in the system, for a system's own page: 839 for Stanton.
json.places_count @places_count

json.terminals @location.terminals.select(&:available).sort_by(&:name) do |terminal|
  json.id terminal.id
  json.name terminal.name
end
