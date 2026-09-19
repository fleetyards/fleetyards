# frozen_string_literal: true

# Keyed on the build as well as the source, for the reason the public partial
# records: re-loading the build we are already on rewrites the fact rows in
# place without touching the blueprint or moving the version string.
json.cache! ["admin", "v1", blueprint, blueprint.facts, ::ScData::Source.current] do
  json.partial! "admin/api/v1/blueprints/base", blueprint: blueprint
end
