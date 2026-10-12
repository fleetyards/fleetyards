# frozen_string_literal: true

json.id manufacturer.id
json.name manufacturer.name
json.long_name manufacturer.long_name || manufacturer.name
json.slug manufacturer.slug
json.code manufacturer.code
json.logo do
  json.partial! "api/v1/shared/file", record: manufacturer, attr: :logo
end
json.icon do
  json.partial! "api/v1/shared/file", record: manufacturer, attr: :icon
end
json.icon_overridden manufacturer.icon_overridden
json.logo_overridden manufacturer.logo_overridden
json.short_name manufacturer.short_name
json.shipyard manufacturer.shipyard
json.partial! "api/v1/locations/linked", key: :shipyard_location, location: manufacturer.shipyard_location

json.partial! "api/shared/dates", record: manufacturer
