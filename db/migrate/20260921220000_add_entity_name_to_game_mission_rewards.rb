# frozen_string_literal: true

# An award states an entity class ref and nothing else, so every item reward
# rendered as a bare GUID. The parser resolves the ref against the export's own
# entity tree -- 405 of the 410 awards in 4.10.1 -- and this is where it lands.
#
# Denormalised on purpose, the way the rest of a build's facts are: most of
# these entities are in no Fleetyards catalogue at all (the scrip, a Banu
# favour), so there is nothing to point a foreign key at.
class AddEntityNameToGameMissionRewards < ActiveRecord::Migration[8.1]
  def change
    add_column :game_mission_rewards, :entity_name, :string
  end
end
