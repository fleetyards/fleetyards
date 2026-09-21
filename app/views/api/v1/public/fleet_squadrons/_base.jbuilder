# frozen_string_literal: true

# Deliberately narrower than the fleet's own partial: no description, and the
# count without the people it counts.
json.id fleet_squadron.id
json.name fleet_squadron.name
json.slug fleet_squadron.slug
json.color fleet_squadron.color

if fleet_squadron.logo.attached?
  json.logo do
    json.partial! "api/v1/shared/file", record: fleet_squadron, attr: :logo
  end
else
  json.logo nil
end
