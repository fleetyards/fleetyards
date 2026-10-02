# frozen_string_literal: true

visitor = local_assigns.fetch(:visitor, false)

# The verification is in the key as well as `updated_at`, which keeps whole
# seconds: a check can answer inside the second of the write before it.
# The headquarters' place is in the key: its name is in the fragment, and
# renaming it does not touch the fleet.
json.cache!((visitor ? ["v4", "visitor", fleet, fleet.rsi_verification_cache_key, fleet.headquarters_location&.link_cache_key] : ["v4", fleet, fleet.rsi_verification_cache_key, fleet.headquarters_location&.link_cache_key]).compact) do
  json.partial!("api/v1/fleets/base", fleet:, visitor:)
end

json.my_fleet(local_assigns.fetch(:my_fleet, false))

# Outside the cache block above on purpose: flag state is not part of the fleet
# record, so a cached copy would keep serving the old answer until the fleet
# itself changed.
json.features fleet.features

# Outside the cache for the same reason as `features` above, and more sharply:
# a subscription is a row in another table, so nothing about the fleet record
# changes when one opens or lapses. A cached copy would keep granting after the
# entitlement stopped.
json.subscribed fleet.subscribed?

if local_assigns.fetch(:my_fleet, false)
  json.calendar_feed_token fleet.calendar_feed_token
end
