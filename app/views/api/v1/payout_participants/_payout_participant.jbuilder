# frozen_string_literal: true

json.cache! ["v2", payout_participant, payout_participant.user] do
  json.partial!("api/v1/payout_participants/base", payout_participant:)
end
