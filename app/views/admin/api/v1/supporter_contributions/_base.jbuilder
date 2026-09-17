# frozen_string_literal: true

json.id supporter_contribution.id
json.name supporter_contribution.name if supporter_contribution.name.present?
json.amount_cents supporter_contribution.amount_cents
json.currency supporter_contribution.currency
json.anonymous supporter_contribution.anonymous
json.recurring supporter_contribution.recurring
json.source supporter_contribution.source
json.patreon_member_id supporter_contribution.patreon_member_id if supporter_contribution.patreon_member_id.present?
json.started_at supporter_contribution.started_at.iso8601
json.ended_at supporter_contribution.ended_at&.iso8601 if supporter_contribution.ended_at.present?
json.note supporter_contribution.note if supporter_contribution.note.present?
json.payer_email supporter_contribution.payer_email if supporter_contribution.payer_email.present?
json.claim_key supporter_contribution.claim_key if supporter_contribution.claim_key.present?
json.linked_via supporter_contribution.linked_via if supporter_contribution.linked_via.present?

if supporter_contribution.user.present?
  json.user_id supporter_contribution.user_id
  json.user do
    json.partial! "admin/api/v1/users/option", user: supporter_contribution.user
  end
end

# The nomination, and whether anything came of it. Both are what an admin needs
# to answer "why does this fleet have access" without opening another page.
if supporter_contribution.fleet.present?
  json.fleet_id supporter_contribution.fleet_id
  json.fleet do
    json.partial! "admin/api/v1/fleets/option", fleet: supporter_contribution.fleet
  end
end

json.seeded_subscription supporter_contribution.fleet_subscriptions.any?

json.partial! "api/shared/dates", record: supporter_contribution
