# frozen_string_literal: true

json.cache! ["v1", paints_import] do
  json.partial!("api/v1/imports/base", import: paints_import)
end
