# frozen_string_literal: true

json.links do
  json.self record.url
  json.frontend record.frontend_url
end
