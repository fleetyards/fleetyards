# frozen_string_literal: true

json.name feature.name
json.state feature.state.to_s

setting = FeatureSetting.find_by(feature_name: feature.name.to_s)

json.selfService setting&.self_service || false
json.selfServiceScope setting&.self_service_scope || FeatureSetting::USER_SCOPE

json.percentageOfActors feature.percentage_of_actors_value
json.percentageOfTime feature.percentage_of_time_value

json.groups feature.groups_value.to_a

actors = feature.actors_value.to_a
json.actors actors.map { |flipper_id|
  type, id = flipper_id.split(";", 2)
  actor_name = case type
  when "User"
    User.find_by(id:)&.username
  when "Fleet"
    Fleet.find_by(id:)&.name
  end
  {type:, id:, name: actor_name || "Unknown"}
}
