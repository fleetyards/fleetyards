# frozen_string_literal: true

json.name feature.name
json.state feature.state.to_s

# A flag Flipper knows but the registry does not is on its way out — the next
# `bin/feature-flags sync` prunes it — so it is never a permanent one.
json.permanent FeatureFlags::Registry.current.fetch(feature.name)&.permanent? || false

setting = FeatureSetting.find_by(feature_name: feature.name.to_s)

json.selfServiceUser setting&.self_service_user || false
json.selfServiceFleet setting&.self_service_fleet || false

json.percentageOfActors feature.percentage_of_actors_value
json.percentageOfTime feature.percentage_of_time_value

json.groups feature.groups_value.to_a

# One lookup per actor type rather than per actor: a rollout flag carries a few
# hundred, and the index renders every flag.
actors = feature.actors_value.to_a.map { |flipper_id| flipper_id.split(";", 2) }
ids_by_type = actors.group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
users = User.where(id: ids_by_type.fetch("User", [])).pluck(:id, :username).to_h
fleets = Fleet.where(id: ids_by_type.fetch("Fleet", [])).pluck(:id, :name, :fid).to_h { |id, name, fid| [id, {name:, fid:}] }

json.actors actors.map { |type, id|
  case type
  when "User"
    {type:, id:, name: users[id] || "Unknown", fid: nil}
  when "Fleet"
    {type:, id:, name: fleets.dig(id, :name) || "Unknown", fid: fleets.dig(id, :fid)}
  else
    {type:, id:, name: "Unknown", fid: nil}
  end
}

# The flag's own history, which flipper_gates cannot supply: its timestamps are
# destroyed by a disable and by the sync that prunes a flag.
summary = feature_summaries[feature.name.to_s]
last_change = summary&.last_change

json.fullyOnSince summary&.fully_on_since
json.lastChangedAt last_change&.created_at
json.lastChangedBy last_change&.actor_label
# Named beside the actor rather than instead of it: sync, the console and the
# backfill have no actor, and "nobody" would otherwise read as missing data.
json.lastChangedSource last_change&.source
