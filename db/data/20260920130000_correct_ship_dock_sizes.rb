# frozen_string_literal: true

# `ship_size` on a hangar was carrying two meanings, and one of them had drifted
# badly. Sorted by envelope length the catalogue reads:
#
#   Galaxy      16m  XXS        Javelin   39m  M
#   Carrack     20m  XS         Polaris   45m  XS
#   Odyssey     29m  XS         Idris    100m  S
#   890 Jump  33.9m  S
#
# The Polaris is the second largest hangar carrying the smallest class, which is
# wrong on any reading of the column. The Galaxy is under by one, and the
# Odyssey is much closer to the Polaris than to the Carrack it currently sits
# with.
#
# The Idris keeps its `small`: a 100m hall is not small, but it is really three
# Gladius-sized pads, and until #5059 records pads the column has nowhere else
# to say so.
#
# Sizes from @mortik, #5063.
class CorrectShipDockSizes < ActiveRecord::Migration[8.1]
  # Keyed on what the row says today, so a hand correction that got there first
  # is left alone rather than being moved to a figure nobody has looked at since.
  CORRECTIONS = [
    {slug: "rsi-galaxy", name: "Hangar", from: "extra_extra_small", to: "extra_small"},
    {slug: "misc-odyssey", name: "Hangar", from: "extra_small", to: "small"},
    {slug: "rsi-polaris", name: "Hangar", from: "extra_small", to: "small"}
  ].freeze

  def up
    CORRECTIONS.each { |correction| apply(correction, correction[:from], correction[:to]) }
  end

  def down
    CORRECTIONS.each { |correction| apply(correction, correction[:to], correction[:from]) }
  end

  private def apply(correction, from, to)
    model = Model.find_by(slug: correction[:slug])

    if model.nil?
      say("no model #{correction[:slug]}")
      return
    end

    dock = model.docks.find_by(name: correction[:name], ship_size: from)

    if dock.nil?
      say("#{correction[:slug]} #{correction[:name]} is no longer #{from}, left alone")
      return
    end

    dock.update!(ship_size: to)
    say("#{correction[:slug]} #{correction[:name]}: #{from} -> #{to}")
  end
end
