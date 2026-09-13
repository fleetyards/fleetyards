# frozen_string_literal: true

json.cache! ["v1", payout_entry] do
  json.partial!("api/v1/payout_entries/base", payout_entry:)
end
