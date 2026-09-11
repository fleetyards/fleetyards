# frozen_string_literal: true

json.cache! ["v1", hangar_sync, local_assigns.fetch(:extended, false)] do
  json.partial!("api/v1/imports/base", import: hangar_sync, extended: local_assigns.fetch(:extended, false))
end
