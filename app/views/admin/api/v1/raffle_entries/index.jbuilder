# frozen_string_literal: true

json.items do
  json.array! @entries, partial: "admin/api/v1/raffle_entries/entry", as: :entry, warnings: @warnings
end
json.partial! "api/shared/meta", result: @entries
