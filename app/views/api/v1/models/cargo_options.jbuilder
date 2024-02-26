# frozen_string_literal: true

json.items do
  json.array! @models, partial: "api/v1/models/cargo_option", as: :model
end
json.partial! "api/shared/meta", result: @models
