# frozen_string_literal: true

json.cache! ["v1", model] do
  json.partial!("admin/api/v1/models/base", model:)
  json.partial! "api/shared/dates", record: model
end
