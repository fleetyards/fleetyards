# frozen_string_literal: true

json.cache! ["v1", payout_transfer] do
  json.partial!("api/v1/payout_transfers/base", payout_transfer:)
end
