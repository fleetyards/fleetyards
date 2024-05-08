# frozen_string_literal: true

json.cache! ["v1", import, local_assigns.fetch(:extended, false)] do
  json.partial!("admin/api/v1/imports/base", import:, extended: local_assigns.fetch(:extended, false))
end
