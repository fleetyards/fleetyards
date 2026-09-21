# frozen_string_literal: true

json.partial! "api/v1/game_missions/base", mission: mission

# What only an admin is shown, and what the questions this section answers are
# asked of: which generator a row came from, whether the game ever named it,
# and which build is answering for it.
json.debug_name mission.debug_name
json.generator_key mission.generator_key

# 74 of the 2,536 have no name anywhere -- no `Title` override, and a template
# whose `displayString` is uninitialised. The public catalogue leaves them out;
# here they are stated, because they are the rows most likely to need a look
# after a load.
json.unnamed mission.name.blank?

json.blueprint_pool_refs mission.blueprint_pool_refs

json.build do
  build = mission.facts

  if build.present?
    json.environment build.environment
    json.version build.version
    # Which of the two `facts` resolved to. A row rendering off `last_build` is
    # a row the current build dropped, and that is worth seeing directly rather
    # than inferring from `retired`.
    json.current build == mission.build
  else
    json.null!
  end
end
