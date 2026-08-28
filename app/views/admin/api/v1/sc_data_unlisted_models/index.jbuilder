# frozen_string_literal: true

json.items do
  json.array!(
    @sc_data_unlisted_models,
    partial: "admin/api/v1/sc_data_unlisted_models/sc_data_unlisted_model",
    as: :sc_data_unlisted_model
  )
end
json.partial! "api/shared/meta", result: @sc_data_unlisted_models
