# frozen_string_literal: true

json.partial! "api/v1/game_missions/base", mission: @mission

# The description is the detail page's alone: it runs to 1,200 characters on the
# longest of them, and a list of 60 would carry 70KB of prose nothing renders.
json.description @mission.description

json.partial! "api/v1/game_missions/rewards", mission: @mission

# The recipes this mission hands out, through the pools it names. Asked with
# the pool refs the build carries rather than by joining `blueprint_sources`
# on the mission's name -- 45 titles are shared by two orgs, so the name is
# not an identity.
json.blueprints @blueprints do |blueprint|
  json.id blueprint.id
  json.name blueprint.name
  json.slug blueprint.slug
end

# Where in the export it came from. Not for reading -- `debug_name` is a
# developer's note -- but it is what makes a row findable in the game files.
json.generator_key @mission.generator_key
json.debug_name @mission.debug_name
