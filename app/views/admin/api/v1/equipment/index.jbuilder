# frozen_string_literal: true

json.items do
  json.array! @equipment, partial: "admin/api/v1/equipment/equipment", as: :equipment
end
json.partial! "api/shared/meta", result: @equipment
