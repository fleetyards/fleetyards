# frozen_string_literal: true

# What the files state for the title's and the description's placeholders. A
# token missing here is the game's to pick when it generates the mission.
json.placeholder_values (mission.placeholder_values || {}).to_a do |(token, value)|
  json.token token
  json.value value
end
