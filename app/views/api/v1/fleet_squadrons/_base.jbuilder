# frozen_string_literal: true

json.id fleet_squadron.id
json.name fleet_squadron.name
json.slug fleet_squadron.slug
json.description fleet_squadron.description
json.color fleet_squadron.color

if fleet_squadron.logo.attached?
  json.logo do
    json.partial! "api/v1/shared/file", record: fleet_squadron, attr: :logo
  end
else
  json.logo nil
end

json.partial! "api/shared/dates", record: fleet_squadron
