# frozen_string_literal: true

json.cache! ["v1", model] do
  json.partial!("api/v1/models/base", model:, extended: local_assigns.fetch(:extended, false))
end
