# frozen_string_literal: true

json.id payout_participant.id
json.payout_ledger_id payout_participant.payout_ledger_id
json.display_name payout_participant.display_name
json.guest payout_participant.guest?

# Omitted rather than null for a guest: UserRef is an object, and a property
# that is present and null does not satisfy it.
if payout_participant.user.present?
  json.user do
    json.id payout_participant.user.id
    json.username payout_participant.user.username
  end
end

json.partial! "api/shared/dates", record: payout_participant
