# frozen_string_literal: true

json.hand_ins mission.facts&.hand_ins.to_a do |hand_in|
  json.kind hand_in.kind
  json.ref hand_in.ref
  json.name hand_in.name
  json.amount hand_in.amount
  json.max hand_in.max
  json.option hand_in.option
end
