# frozen_string_literal: true

json.cache! ["v2", payout_entry, payout_entry.payout_participant&.user] do
  json.partial!("api/v1/payout_entries/base", payout_entry:)
end
