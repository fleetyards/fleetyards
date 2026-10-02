# frozen_string_literal: true

json.groups @groups do |group|
  json.kind group.kind
  json.count group.count

  json.entries group.entries do |entry|
    json.name entry.name
    json.count entry.count
    json.shown_on_starmap entry.shown_on_starmap
    json.location do
      json.partial! "api/v1/locations/link", location: entry.location
    end
  end
end
