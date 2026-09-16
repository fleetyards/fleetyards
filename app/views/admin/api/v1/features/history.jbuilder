# frozen_string_literal: true

json.array! @changes do |change|
  json.id change.id
  json.operation change.operation
  json.gateName change.gate_name
  json.thing change.thing
  json.stateAfter change.state_after
  json.source change.source
  json.actor change.actor_label
  json.createdAt change.created_at
end
