# frozen_string_literal: true

json.cache! ["v1", model, local_assigns.fetch(:extended, false)] do
  json.partial!("admin/api/v1/models/base", model:, extended: local_assigns.fetch(:extended, false))
end
