# frozen_string_literal: true

json.items do
  json.array! @raffles do |raffle|
    json.partial! "admin/api/v1/raffles/raffle", raffle:, entries_count: @entries_counts.fetch(raffle.id, 0)
  end
end
json.partial! "api/shared/meta", result: @raffles
