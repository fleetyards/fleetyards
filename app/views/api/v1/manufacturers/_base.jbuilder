# frozen_string_literal: true

json.name manufacturer.name
json.long_name manufacturer.long_name || manufacturer.name
json.slug manufacturer.slug
json.code manufacturer.code
json.logo do
  json.partial! "api/v1/shared/file", record: manufacturer, attr: :logo
end

json.partial! "api/shared/dates", record: manufacturer
