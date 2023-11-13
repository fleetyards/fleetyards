# frozen_string_literal: true

json.items do
  json.array! @commodities, partial: "api/v1/commodities/commodity", as: :commodity
end
json.partial! "api/shared/meta", result: @commodities
