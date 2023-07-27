# frozen_string_literal: true

json.cache! ["v1", model] do
  json.partial!("api/v1/models/base", model:)
  json.dock_counts do
    json.array! model.dock_counts, partial: "api/v1/dock_counts/base", as: :dock_count
  end
  json.partial! "api/shared/dates", record: model
  json.partial! "api/shared/links", record: model
end
