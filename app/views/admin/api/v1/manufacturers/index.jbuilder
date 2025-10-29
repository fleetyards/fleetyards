# frozen_string_literal: true

json.items do
  json.array! @manufacturers, partial: "admin/api/v1/manufacturers/manufacturer", as: :manufacturer
end
json.partial! "api/shared/meta", result: @manufacturers
