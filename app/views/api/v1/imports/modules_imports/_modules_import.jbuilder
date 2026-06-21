# frozen_string_literal: true

json.cache! ["v1", modules_import] do
  json.partial!("api/v1/imports/base", import: modules_import)
end
