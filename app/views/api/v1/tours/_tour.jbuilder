# frozen_string_literal: true

json.cache! ["v1", tour] do
  json.partial!("api/v1/tours/base", tour:)
end

# The invite token is a credential, so it only goes to the organiser -- and it
# depends on the viewer, which is exactly what must not be cached above.
json.invite_token((tour.created_by_id == @viewer&.id) ? tour.invite_token : nil)
json.payout_ledger_id tour.payout_ledger&.id
