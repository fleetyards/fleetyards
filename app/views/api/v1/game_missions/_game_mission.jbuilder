# frozen_string_literal: true

# The build itself is in the key, not just the source.
#
# Every fact in this payload comes off a build record, and re-loading the build
# we are already on rewrites those rows in place without touching the mission or
# moving the version string. Keyed on the source alone, a re-import would go on
# serving the previous values until something else happened to touch the row.
json.cache! ["v1", mission, mission.facts, ::ScData::Source.current] do
  json.partial! "api/v1/game_missions/base", mission:
end
