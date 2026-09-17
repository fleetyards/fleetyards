# frozen_string_literal: true

json.id fleet_subscription.id
json.started_at fleet_subscription.started_at.iso8601
json.ended_at fleet_subscription.ended_at&.iso8601 if fleet_subscription.ended_at.present?
json.granted_via fleet_subscription.granted_via
json.note fleet_subscription.note if fleet_subscription.note.present?
json.open fleet_subscription.open?
json.active fleet_subscription.active_on?

json.fleet do
  json.partial! "admin/api/v1/fleets/option", fleet: fleet_subscription.fleet
end

# Present only on a row the reconciler seeded, which is what tells an admin
# whether closing it by hand will stick or be reopened by the next sync.
if fleet_subscription.supporter_contribution.present?
  json.supporter_contribution_id fleet_subscription.supporter_contribution_id
  json.supporter_contribution do
    json.id fleet_subscription.supporter_contribution.id
    json.amount_cents fleet_subscription.supporter_contribution.amount_cents
    json.currency fleet_subscription.supporter_contribution.currency
    json.display_name fleet_subscription.supporter_contribution.display_name
  end
end

json.partial! "api/shared/dates", record: fleet_subscription
