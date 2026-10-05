# frozen_string_literal: true

json.cache! ["v2", payout_transfer, payout_transfer.from_participant&.user, payout_transfer.to_participant&.user] do
  json.partial!("api/v1/payout_transfers/base", payout_transfer:)
end
