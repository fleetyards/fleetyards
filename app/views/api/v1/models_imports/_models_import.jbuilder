# frozen_string_literal: true

json.cache! ["v1", models_import] do
  json.partial!("api/v1/imports/base", import: models_import, extened: true)
end
