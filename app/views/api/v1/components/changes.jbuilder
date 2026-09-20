# frozen_string_literal: true

json.array! @changes do |change|
  json.id change.id
  json.environment change.environment
  json.from_version change.from_version
  json.to_version change.to_version

  # The field without the `type_data.` prefix, plus a flag saying whether it had
  # one. A reader labels a metric from the same key the payload spells it under
  # -- the prefix is how the log keeps `type_data.size` apart from the `size`
  # column, and it is storage rather than something to render.
  json.field change.field_name
  json.metric change.metric?

  json.old_value change.old_value
  json.new_value change.new_value
  json.recorded_at change.recorded_at
end
