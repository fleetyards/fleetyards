# frozen_string_literal: true

json.items do
  json.array! @model_upgrades, partial: "admin/api/v1/model_upgrades/model_upgrade", as: :model_upgrade
end
json.partial! "api/shared/meta", result: @model_upgrades
