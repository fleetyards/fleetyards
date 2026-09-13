# frozen_string_literal: true

json.cache! ["v1", payout_participant] do
  json.partial!("api/v1/payout_participants/base", payout_participant:)
end
