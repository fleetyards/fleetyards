# frozen_string_literal: true

json.partial! "api/shared/pagination_metadata", scope: @models, model: Model
json.items do
  json.array! @models, partial: "api/v2/models/minimal", as: :model
end
