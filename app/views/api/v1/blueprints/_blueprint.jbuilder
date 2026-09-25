# frozen_string_literal: true

# The build itself is in the key, not just the source.
#
# Every fact in this payload -- the name, the craft time, `sourceUnknown` --
# comes off a build record, and re-loading the build we are already on rewrites
# those rows in place without touching the blueprint or moving the version
# string. Keyed on the source alone, a re-import would go on serving the
# previous values until something else happened to touch the row.
#
# What it makes is in the key for the same reason: the payload carries its
# name, slug and whether it has a page, and hiding a variant touches the
# variant, not the recipe.
json.cache! ["v2", blueprint, blueprint.facts, blueprint.craftable, ::ScData::Source.current] do
  json.partial! "api/v1/blueprints/base", blueprint:
end

# Outside the cache, and it has to stay there. The key above names the
# blueprint, its build and the source -- no reader anywhere in it -- so an
# `owned` emitted inside would hand the first reader's answer to everyone who
# opened the catalogue after them.
json.owned @owned_blueprint_ids.include?(blueprint.id)
