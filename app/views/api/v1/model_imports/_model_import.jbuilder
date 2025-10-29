# frozen_string_literal: true

json.cache! ["v1", model_import] do
  json.partial!("api/v1/imports/base", import: model_import, extended: true)
end
