# frozen_string_literal: true

json.items do
  json.array! @models, partial: "admin/api/v1/models/model", as: :model
end
json.partial! "api/shared/meta", result: @models
