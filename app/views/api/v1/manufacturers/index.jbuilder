# frozen_string_literal: true

json.items do
  json.array! @manufacturers, partial: "api/v1/manufacturers/minimal", as: :manufacturer
end
json.partial! "api/shared/meta", result: @manufacturers
