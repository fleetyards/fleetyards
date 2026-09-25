# frozen_string_literal: true

json.id payout_participant.id
json.payout_ledger_id payout_participant.payout_ledger_id
json.display_name payout_participant.display_name
json.guest payout_participant.guest?
json.weight payout_participant.weight

# Omitted rather than null for a guest: UserRef is an object, and a property
# that is present and null does not satisfy it.
if payout_participant.user.present?
  json.user do
    json.id payout_participant.user.id
    json.username payout_participant.user.username
  end
end

if payout_participant.fleet.present?
  json.fleet do
    json.id payout_participant.fleet.id
    json.name payout_participant.fleet.name
    json.slug payout_participant.fleet.slug

    if payout_participant.fleet.logo.attached?
      json.logo do
        json.partial! "api/v1/shared/file", record: payout_participant.fleet, attr: :logo
      end
    end
  end
end

json.partial! "api/shared/dates", record: payout_participant
