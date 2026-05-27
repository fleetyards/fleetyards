# frozen_string_literal: true

json.items do
  json.array! @model_snub_crafts, partial: "admin/api/v1/model_snub_crafts/model_snub_craft", as: :model_snub_craft
end

json.partial! "api/shared/meta", result: @model_snub_crafts
