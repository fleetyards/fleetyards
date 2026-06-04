# frozen_string_literal: true

json.cache! ["admin/v1/manufacturers/option", manufacturer] do
  json.id manufacturer.id
  json.name manufacturer.name
  json.slug manufacturer.slug

  json.logo do
    json.partial! "api/v1/shared/file", record: manufacturer, attr: :logo
  end
end
