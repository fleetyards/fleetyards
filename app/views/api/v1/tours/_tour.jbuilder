# frozen_string_literal: true

json.cache! ["v1", tour, tour.created_by, tour.fleet] do
  json.partial!("api/v1/tours/base", tour:)
end

# The invite token is a credential, so it only goes to whoever may hand it out
# -- the organiser, and a payout manager of the fleet a tour belongs to, who
# can also rotate it. It depends on the viewer, which is exactly what must not
# be cached above.
may_invite = tour.created_by_id == @viewer&.id ||
  (tour.fleet_id.present? && @payout_manager_fleet_ids.to_a.include?(tour.fleet_id))

json.invite_token(may_invite ? tour.invite_token : nil)
json.payout_ledger_id tour.payout_ledger&.id

# What the viewer's own standing on this tour is, so the page knows whether to
# offer asking onto it. Both come from a set resolved once per response rather
# than a lookup per row.
json.participating @participating_tour_ids.to_a.include?(tour.id)

pending_join_request_id = @pending_join_request_ids.to_h[tour.id]

json.join_request_pending pending_join_request_id.present?
json.join_request_id pending_join_request_id
