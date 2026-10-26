# frozen_string_literal: true

# Keyed on the build as well as the source, for the reason the public partial
# records: re-loading the build we are already on rewrites the fact rows in
# place without touching the blueprint or moving the version string. What it
# makes is in it for the same reason: attaching a render touches the item, not
# the recipe. v2 is `craftable.angledView`.
json.cache! ["admin", "v2", blueprint, blueprint.facts, blueprint.craftable, ::ScData::Source.current] do
  json.partial! "admin/api/v1/blueprints/base", blueprint: blueprint
end
