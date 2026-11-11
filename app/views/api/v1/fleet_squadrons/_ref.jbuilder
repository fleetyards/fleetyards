# frozen_string_literal: true

json.id fleet_squadron.id
json.name fleet_squadron.name
json.slug fleet_squadron.slug
json.color fleet_squadron.color
json.team fleet_squadron.team

if fleet_squadron.icon.attached?
  json.icon do
    json.partial! "api/v1/shared/file", record: fleet_squadron, attr: :icon
  end
else
  json.icon nil
end
