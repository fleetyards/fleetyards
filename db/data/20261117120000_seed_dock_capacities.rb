# frozen_string_literal: true

# Says what every berth in the catalogue is built for. A dock without an entry
# answers will-it-fit from its envelope with clearance, which is wrong wherever
# the recorded dimensions are.
#
# Vehicle berths take the largest rung whose reference vehicle the envelope
# admits, which settles the cases the envelope got wrong once and for all: the
# Starfarer garage is measured too small for an Ursa and takes one in game.
# Hangars keep the pad class they were already curated to, except the Idris,
# whose hall is three small pads rather than one.
#
# The first entry of each dock is the one its label renders from. Entries under
# one dock are alternatives: the Kraken's main deck takes one large ship or two
# medium ones.
class SeedDockCapacities < ActiveRecord::Migration[8.1]
  URSA = [["vehicle", "large", 1]].freeze
  NOVA = [["vehicle", "extra_extra_large", 1]].freeze

  STANDARD_VEHICLE_BAY = %w[
    orig-600i-explorer anvl-carrack drak-corsair misc-freelancer-max
    rsi-constellation-mk-iv-andromeda rsi-constellation-mk-iv-aquila
    rsi-constellation-mk-iv-phoenix
  ].freeze

  EXISTING = [
    *STANDARD_VEHICLE_BAY.map { |slug| [slug, "garage", URSA] },
    ["aegs-hammerhead", "cargogrid", URSA],
    ["anvl-valkyrie", "cargogrid", URSA],
    ["misc-starfarer", "garage", URSA],
    ["misc-starfarer-gemini", "garage", URSA],
    ["drak-cutlass-black", "garage", [["vehicle", "medium", 1]]],
    ["rsi-polaris", "garage", [["vehicle", "extra_large", 1]]],
    ["orig-890-jump", "garage", NOVA],
    ["crus-a2-hercules", "cargogrid", NOVA],
    ["crus-c2-hercules", "cargogrid", NOVA],
    ["crus-m2-hercules", "cargogrid", NOVA],

    ["rsi-galaxy", "hangar", [["ship", "extra_small", 1]]],
    ["anvl-carrack", "hangar", [["ship", "extra_small", 1]]],
    ["misc-odyssey", "hangar", [["ship", "small", 1]]],
    ["orig-890-jump", "hangar", [["ship", "small", 1]]],
    ["rsi-polaris", "hangar", [["ship", "small", 1]]],
    ["aegs-javelin", "hangar", [["ship", "medium", 1]]],
    ["aegs-idris-m", "hangar", [["ship", "small", 3]]],
    ["aegs-idris-p", "hangar", [["ship", "small", 3]]],
    ["banu-merchantman", "landingpad", [["ship", "extra_small", 1]]]
  ].freeze

  KRAKEN_DOCKS = [
    {name: "Main Deck", dock_type: "landingpad", ship_size: "large",
     entries: [["ship", "large", 1], ["ship", "medium", 2]]},
    {name: "Side Pads", dock_type: "landingpad", ship_size: "small",
     entries: [["ship", "small", 4]]},
    {name: "Hangars", dock_type: "hangar", ship_size: "small",
     entries: [["ship", "small", 2]]}
  ].freeze

  MISSING = {
    "rsi-constellation-mk-iv-taurus" => [
      {name: "Garage", dock_type: "garage", ship_size: "extra_small",
       length: 10.0, beam: 7.0, height: 6.0, entries: URSA}
    ],
    "drak-kraken" => KRAKEN_DOCKS,
    "drak-kraken-privateer" => KRAKEN_DOCKS,
    "anvl-liberator" => [
      {name: "Ship Deck", dock_type: "landingpad", ship_size: "small",
       entries: [["ship", "small", 3]]},
      {name: "Vehicle Deck", dock_type: "garage", ship_size: "extra_small", entries: NOVA}
    ]
  }.freeze

  def up
    missing = []

    EXISTING.each do |slug, dock_type, entries|
      model = Model.find_by(slug:)
      dock = model && Dock.find_by(parent: model, dock_type:)

      if dock.nil?
        missing << "#{slug} #{dock_type}"
        next
      end

      describe(dock, entries)
    end

    MISSING.each do |slug, docks|
      model = Model.find_by(slug:)

      if model.nil?
        missing << slug
        next
      end

      docks.each do |attributes|
        dock = Dock.find_or_create_by!(parent: model, name: attributes[:name]) do |new_dock|
          new_dock.assign_attributes(attributes.except(:name, :entries))
        end

        describe(dock, attributes[:entries])
      end
    end

    say("no dock for: #{missing.join(", ")}") if missing.any?
  end

  # Not reversible: a rollback cannot tell a seeded dock or entry from one an
  # admin added or corrected afterwards.
  def down
    raise ActiveRecord::IrreversibleMigration
  end

  # A dock somebody has already described in admin keeps what they entered.
  private def describe(dock, entries)
    return if dock.capacities.exists?

    entries.each_with_index do |(ladder, size, quantity), index|
      dock.capacities.create!(ladder:, size:, quantity:, display: index.zero?)
    end
  end
end
