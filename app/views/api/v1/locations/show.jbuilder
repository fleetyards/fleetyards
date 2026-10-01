# frozen_string_literal: true

json.partial! "api/v1/locations/base", location: @location

json.description @location.description

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

json.terminals @location.terminals.sort_by(&:name) do |terminal|
  json.id terminal.id
  json.name terminal.name
end
