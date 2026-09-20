# frozen_string_literal: true

# #4868 built the ladder -- the column, the seven values, the admin select, the
# filter -- and seeded nothing, so it matched no ship. This is the seed.
#
# Curated, not derived. Volume gets the rough shape right and the boundaries
# wrong: the Cyclone is recorded 8.75m wide, wider than an Ursa, which would put
# it a class above the vehicle it sits beside -- and the Carrack garage is
# exactly where that question is decided. The Dragonfly is Cyclone-sized by
# volume and a bike by every other measure.
#
# Anchors and placement are @mortik's, from docs/exec-plans/4863-berth-model.md.
# Three of them are a first answer rather than a settled one: the Dragonfly
# (bike, at Cyclone volume), the Storm (alone between the Ursa and the Nova) and
# the MDC/MTC pair (between the Cyclone and the Ursa with nothing to break the
# tie). Correcting one is a click in admin.
class SeedVehicleSizeLadder < ActiveRecord::Migration[8.1]
  LADDER = {
    "extra_extra_small" => %w[argo-atls argo-atls-geo],
    "extra_small" => %w[
      mrai-pulse mrai-pulse-lx xnaa-nox xnaa-nox-kue cnou-hoverquad orig-x1 orig-x1-force
      orig-x1-velocity drak-dragonfly-black drak-dragonfly-yellowjacket
      drak-dragonfly-starkitten-edition
    ],
    "small" => %w[grin-ptv grin-utv grin-stv tmbl-ranger-cv tmbl-ranger-rc tmbl-ranger-tr],
    "medium" => %w[
      tmbl-cyclone tmbl-cyclone-aa tmbl-cyclone-mt tmbl-cyclone-rc tmbl-cyclone-rn
      tmbl-cyclone-tr drak-mule grin-roc argo-csv-sm grin-mdc grin-mtc
    ],
    "large" => %w[
      rsi-ursa rsi-ursa-fortuna rsi-ursa-medivac rsi-lynx grin-roc-ds orig-g12 orig-g12a orig-g12r
    ],
    "extra_large" => %w[tmbl-storm tmbl-storm-aa],
    "extra_extra_large" => %w[tmbl-nova anvl-centurion anvl-spartan anvl-ballista]
  }.freeze

  # Only a model that is a vehicle and has no class yet. The validation refuses
  # a ladder value on a ship, and an admin who has already placed one by hand
  # has said something this list has not.
  def up
    missing = []

    LADDER.each do |size, slugs|
      scope = Model.where(slug: slugs, size: Model::VEHICLE_SIZE, vehicle_size: nil)
      placed = scope.update_all(vehicle_size: size)

      say("#{placed} placed at #{size}")

      missing += slugs - Model.where(slug: slugs).pluck(:slug)
    end

    say("no model for: #{missing.join(", ")}") if missing.any?

    unplaced = Model.where(size: Model::VEHICLE_SIZE, vehicle_size: nil).pluck(:slug)
    say("still without a class: #{unplaced.join(", ")}") if unplaced.any?
  end

  # The column held nothing before this, on every vehicle.
  def down
    Model.where(slug: LADDER.values.flatten).update_all(vehicle_size: nil)
  end
end
