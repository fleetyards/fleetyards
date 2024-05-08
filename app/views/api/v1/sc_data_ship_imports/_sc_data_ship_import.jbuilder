# frozen_string_literal: true

json.cache! ["v1", sc_data_ship_import] do
  json.partial!("api/v1/imports/base", import: sc_data_ship_import, extended: true)
end
