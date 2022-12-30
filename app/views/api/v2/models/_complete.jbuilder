# frozen_string_literal: true

json.cache! ['v2', model] do
  json.partial! 'api/v2/models/base', model: model
  json.docks do
    json.array! model.dock_counts, partial: 'api/v2/models/dock', as: :dock_count
  end
  json.partial! 'api/shared/dates', record: model
  json.partial! 'api/shared/record_links', record: model
end
