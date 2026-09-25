# frozen_string_literal: true

json.cache! ["v1", uex_equipment_prices_import] do
  json.partial!("api/v1/imports/base", import: uex_equipment_prices_import)
end
