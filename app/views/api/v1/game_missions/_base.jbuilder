# frozen_string_literal: true

json.id mission.id
json.slug mission.slug

# Both carry `~mission(Location|Address)` spans the game fills in at run time,
# and the description carries the game's own `<EM4>` emphasis markup. Passed on
# as the export writes them: stripping a span breaks the sentence around it, so
# what to do with one is the renderer's decision and not this payload's.
json.name mission.name
json.sc_key mission.sc_key
json.sc_ref mission.sc_ref

# "career" or "contract".
json.kind mission.kind

json.retired mission.retired?

# Whether the build is offering it at all. False for the 349 contracts flagged
# `notForRelease` or `workInProgress` -- in the files, in front of nobody.
json.released mission.released

# Who offers it. Null on 197: a handler naming no faction takes its generator's
# org, and only where that generator names exactly one -- a wrong org is worse
# than none when "who gives me this" is the question the row answers.
if mission.org_name.present?
  json.org do
    json.name mission.org_name
    json.key mission.org_key
    # What the export states, and what we curate from it. "neutral" is ours to
    # name: the game states a boolean and nothing else.
    json.alignment mission.alignment
    json.lawful mission.org_lawful
  end
end

# The band it is offered in, which is what a player reads as VHRT and up.
json.min_standing mission.min_standing
json.max_standing mission.max_standing

# Four axes, each 1-7 as the game's own designers rated it. The sentence the
# export writes the number on the end of is developer-facing and is not carried.
if mission.difficulty_profile.present?
  json.difficulty do
    json.profile mission.difficulty_profile
    json.mechanical_skill mission.difficulty_mechanical_skill
    json.mental_load mission.difficulty_mental_load
    json.risk_of_loss mission.difficulty_risk_of_loss
    json.game_knowledge mission.difficulty_game_knowledge
  end
end

# What kinds of thing it pays, for a row that has no space for the amounts.
json.reward_kinds mission.reward_kinds

json.created_at mission.created_at
json.updated_at mission.updated_at
