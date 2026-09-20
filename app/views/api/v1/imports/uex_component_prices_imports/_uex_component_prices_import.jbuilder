# frozen_string_literal: true

json.cache! ["v1", uex_component_prices_import] do
  json.partial!("api/v1/imports/base", import: uex_component_prices_import)
end
