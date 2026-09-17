# frozen_string_literal: true

# The fleet and the subscription are rendered here but are not the
# contribution's own columns, so neither moves its `updated_at`. Without them
# in the key a renamed fleet stays stale and `seededSubscription` never flips
# when the reconciler opens one.
json.cache! ["v2", supporter_contribution, supporter_contribution.user,
  supporter_contribution.fleet, supporter_contribution.fleet_subscriptions.maximum(:updated_at)] do
  json.partial!("admin/api/v1/supporter_contributions/base", supporter_contribution:)
end
