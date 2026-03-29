# frozen_string_literal: true

json.cache! ["v1", all_import] do
  json.partial!("api/v1/imports/base", import: all_import, extended: true)
end
