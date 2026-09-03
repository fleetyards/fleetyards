# frozen_string_literal: true

json.array! @changes do |change|
  json.id change.id
  json.environment change.environment
  json.from_version change.from_version
  json.to_version change.to_version
  json.field change.field
  json.old_value change.old_value
  json.new_value change.new_value
  json.recorded_at change.recorded_at
end
