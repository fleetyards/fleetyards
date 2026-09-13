# frozen_string_literal: true

json.items do
  json.array! @payout_entries, partial: "api/v1/payout_entries/payout_entry", as: :payout_entry
end
json.partial! "api/shared/meta", result: @payout_entries
