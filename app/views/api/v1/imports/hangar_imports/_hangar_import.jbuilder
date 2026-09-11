# frozen_string_literal: true

json.cache! ["v1", hangar_import, local_assigns.fetch(:extended, false)] do
  json.partial!("api/v1/imports/base", import: hangar_import, extended: local_assigns.fetch(:extended, false))
end
