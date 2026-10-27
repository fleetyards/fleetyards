# frozen_string_literal: true

json.items do
  json.array! @raffles do |raffle|
    json.partial! "api/v1/raffles/raffle", raffle:, viewer_entry: @viewer_entries[raffle.id]
  end
end
json.partial! "api/shared/meta", result: @raffles
