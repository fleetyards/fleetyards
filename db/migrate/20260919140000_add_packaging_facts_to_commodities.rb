# frozen_string_literal: true

# Three more things the game files say about a commodity, none of which the
# catalogue carried.
#
# `consumable` -- whether a player can eat or drink it. Ten of the 232: nine
# harvestables you pick and eat, and SLAM. The 297 other consumable entities in
# the build name no commodity, because a bottle is an item and the crate of
# drink is the good.
#
# `container_sizes` -- every size it is packaged in, in SCU, from the
# hand-carried forms below one up to the 32 SCU freight crate. 209 of the 232
# declare at least one; the rest are the refuel and rearm goods, which are
# hauled in generic containers and have no crate entity anywhere.
#
# `refines_into_id` -- the refined good an ore or raw form becomes. Held on the
# row rather than layered onto the build, the way `manufacturer_id` is on
# equipment and components: an association is not a fact a build states about
# one record, and the loader has to resolve it in a second pass anyway.
#
# That means live and ptu share one answer and the last load wins, which is the
# same trade those two columns already make. Measured across both builds of
# 4.10.1, all 232 commodities agree on every one of these facts, so the two
# loads currently write the same 30 links -- but a build that disagreed would
# be invisible here, and moving this onto `commodity_builds` is what that would
# cost.
class AddPackagingFactsToCommodities < ActiveRecord::Migration[8.1]
  def change
    add_column :commodities, :consumable, :boolean, null: false, default: false
    add_column :commodity_builds, :consumable, :boolean, null: false, default: false

    # `null: false` because every reader calls `.map` on it unconditionally --
    # an empty list is the answer for the 42 commodities nothing packages, and a
    # null there would be a `NoMethodError` rather than a different answer.
    add_column :commodities, :container_sizes, :decimal, precision: 16, scale: 8, array: true, default: [], null: false
    add_column :commodity_builds, :container_sizes, :decimal, precision: 16, scale: 8, array: true, default: [], null: false

    # Nullify rather than cascade: a refined good being retired must not take
    # the ore's row with it, and the ore is still an ore.
    add_reference :commodities, :refines_into, type: :uuid, null: true,
      foreign_key: {to_table: :commodities, on_delete: :nullify}, index: true
  end
end
