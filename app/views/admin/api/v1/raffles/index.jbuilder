# frozen_string_literal: true

json.items do
  json.array! @raffles, partial: "admin/api/v1/raffles/raffle", as: :raffle
end
json.partial! "api/shared/meta", result: @raffles
