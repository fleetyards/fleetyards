# frozen_string_literal: true

json.items do
  json.array! @commodities, partial: "admin/api/v1/commodities/minimal", as: :commodity
end
json.partial! "api/shared/meta", result: @commodities
