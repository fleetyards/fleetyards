# frozen_string_literal: true

json.items do
  json.array! @tours, partial: "api/v1/tours/tour", as: :tour
end
json.partial! "api/shared/meta", result: @tours
