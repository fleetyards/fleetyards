# frozen_string_literal: true

json.cache! ["v1", blueprint_log_import, local_assigns.fetch(:extended, false)] do
  json.partial!("api/v1/imports/base", import: blueprint_log_import, extended: local_assigns.fetch(:extended, false))
end
