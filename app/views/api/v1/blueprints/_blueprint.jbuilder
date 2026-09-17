# frozen_string_literal: true

# The build itself is in the key, not just the source.
#
# Every fact in this payload -- the name, the craft time, `sourceUnknown` --
# comes off a build record, and re-loading the build we are already on rewrites
# those rows in place without touching the blueprint or moving the version
# string. Keyed on the source alone, a re-import would go on serving the
# previous values until something else happened to touch the row.
json.cache! ["v1", blueprint, blueprint.facts, ::ScData::Source.current] do
  json.partial! "api/v1/blueprints/base", blueprint:
end
