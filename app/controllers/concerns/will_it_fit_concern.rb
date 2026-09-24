# frozen_string_literal: true

# One answer to "will it fit", for the ship list and the hangar alike.
#
# There used to be two. The ship list compared against every dock with half a
# metre of clearance and no notion of dock type; the hangar took the largest ship
# and vehicle dock, told ground vehicles from ships, and allowed two metres. As
# filters the disagreement was survivable — nobody sees both answers at once.
# Stating one of them on a ship's page is not, so the hangar's rule is the one
# that stayed: it is the one that knows a garage from a landing pad.
#
# Both callers scope a relation that has `models` available — the ship list
# scopes `Model` itself, the hangar a `Vehicle` joined to it — so the conditions
# are written against that table rather than the scope's own.
module WillItFitConcern
  private def will_it_fit_scope(scope, carrier)
    return scope if carrier.blank?

    # Every measured berth, not the longest of each kind: length alone does not
    # dominate, so a 90x40 dock takes what a 100x20 cannot and picking by length
    # made the filter disagree with `Model#carried_by_with_docks`, which walks
    # them all.
    # A described berth takes part whether or not anybody measured it -- that is
    # the point of the class. The Merchantman's pad has no dimensions and can
    # still answer once somebody says what it is for.
    docks = carrier.berths.select do |dock|
      dock.berth? && (dock.described? || dock.added_model_ids.any? || dock.measured?)
    end

    # A carrier nobody measured cannot answer, and filtering everything away
    # would state that nothing fits.
    return scope if docks.blank?

    # Both branches are built from `scope` so they stay the same class and stay
    # structurally compatible. `or` demands both and refuses a bare Hash, which
    # is what the hangar used to hand it.
    branches = docks.filter_map { |dock| dock_branch(scope, dock) }

    # A carrier whose every berth came back empty-handed cannot answer, which is
    # not the same as answering "nothing fits".
    return scope if branches.empty?

    branches.reduce { |combined, branch| combined.or(branch) }
  end

  # A described berth answers by its class and the ships named on it, and by
  # nothing else -- adding everything that physically fits would put the medium
  # ship back in the Idris.
  #
  # An undescribed one still answers by its envelope, and the names are added to
  # that rather than replacing it: a berth nobody has described has not said
  # that the ship it names is the only one it takes. `Dock#fits?` reads the same
  # way, and the two must not disagree -- the ship list and the hangar once
  # answered this with different rules.
  private def dock_branch(scope, dock)
    branches = named_branch(scope, dock)

    branches += if dock.described?
      [class_branch(scope, dock, "ship"), class_branch(scope, dock, "vehicle")]
    else
      [envelope_branch(scope, dock)]
    end

    branches.compact.reduce { |combined, branch| combined.or(branch) }
  end

  private def named_branch(scope, dock)
    named = dock.added_model_ids

    named.any? ? [scope.where(models: {id: named})] : []
  end

  # Everything of the largest class recorded, and below. The two ladders are
  # asked differently because they are stored differently: a ship's class is an
  # integer enum, a vehicle's a string on a curated list.
  private def class_branch(scope, dock, ladder)
    rungs = ::DockCapacity::LADDER_CLASSES.fetch(ladder)
    largest = dock.capacities
      .select { |capacity| capacity.ladder == ladder }
      .filter_map { |capacity| rungs.index(capacity.size) }
      .max

    return if largest.nil?

    return vehicle_class_branch(scope, rungs, largest) if ladder == "vehicle"

    ship_class_branch(scope, rungs, largest)
  end

  private def vehicle_class_branch(scope, rungs, largest)
    scope.where(models: {size: ::Model::VEHICLE_SIZE})
      .where("array_position(ARRAY[?]::varchar[], models.vehicle_size) <= ?", rungs, largest + 1)
  end

  # A hull carries its class once a holo has been measured. Before that -- which
  # is nearly all of them -- the pad's own box answers instead, which is the
  # same question asked of the hull rather than of a column, and the box is the
  # game's.
  private def ship_class_branch(scope, rungs, largest)
    ships = scope.where.not(models: {size: ::Model::VEHICLE_SIZE})

    # The top rung is what a hull larger than every box comes back as, so there
    # is nothing left for the box to exclude -- `Dock.ship_size_for` says the
    # same, and the two paths disagreeing is the thing this replaced.
    if largest == rungs.length - 1
      return ships.where("models.dock_size IS NOT NULL OR models.length > 0")
    end

    box = ::Dock::SHIP_SIZE_METRICS.fetch(rungs[largest].to_sym)
    pad = [box[:x].to_f, box[:y].to_f].sort.reverse

    ships.where(
      "(models.dock_size IS NOT NULL AND models.dock_size <= :rung)
       OR (models.dock_size IS NULL
           AND models.length > 0
           AND GREATEST(models.length, models.beam) <= :long
           AND LEAST(models.length, models.beam) <= :short
           AND models.height <= :tall)".squish,
      rung: largest, long: pad.first, short: pad.last, tall: box[:z].to_f
    )
  end

  # Nil for a berth nobody measured: it has nothing to compare against, and a
  # dock with neither measurements nor a description answers nothing at all.
  private def envelope_branch(scope, dock)
    return unless dock.measured?

    clearance = dock.clearance

    # Ranges open at the bottom would let a model with no dimensions through as
    # a fit, which is what a zero means here. `carried_by_with_docks` refuses
    # those too.
    dimensions = {
      length: 0.001..(dock.length - clearance[:length]),
      beam: 0.001..(dock.beam - clearance[:beam]),
      height: 0.001..(dock.height - clearance[:height])
    }

    # `size`, not `ground`: the latter means "cannot reach space", so a hover bike
    # is ground: false while still berthing as a vehicle. See Dock#fits?.
    if dock.for_vehicles?
      return scope.where(models: {size: ::Model::VEHICLE_SIZE}.merge(dimensions))
    end

    # `where.not` drops a null size along with the vehicles, which is what we
    # want: the two models without one are planetary beacons.
    scope.where(models: dimensions).where.not(models: {size: ::Model::VEHICLE_SIZE})
  end

  private def will_it_fit_carrier(slug)
    return if slug.blank?

    # Each branch is built from the same scoped relation. Written as
    # `Model.visible.active.where(slug:).or(Model.where(rsi_slug:))`, only the
    # first branch carried visible/active and a hidden model could be resolved
    # through its rsi or legacy slug.
    scoped = Model.visible.active

    scoped.where(slug: slug)
      .or(scoped.where(rsi_slug: slug))
      .or(scoped.where(legacy_slug: slug))
      .first
  end
end
