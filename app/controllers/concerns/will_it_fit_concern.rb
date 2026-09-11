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

    docks = carrier.docks.to_a
    ship_dock = ::Dock.largest_ship_dock(docks)
    vehicle_dock = ::Dock.largest_vehicle_dock(docks)

    # A carrier nobody measured cannot answer, and filtering everything away
    # would state that nothing fits.
    return scope if ship_dock.blank? && vehicle_dock.blank?

    # Both branches are built from `scope` so they stay the same class and stay
    # structurally compatible. `or` demands both and refuses a bare Hash, which
    # is what the hangar used to hand it.
    branches = [
      dock_branch(scope, ship_dock),
      dock_branch(scope, vehicle_dock)
    ].compact

    branches.reduce { |combined, branch| combined.or(branch) }
  end

  private def dock_branch(scope, dock)
    return if dock.blank?

    clearance = dock.clearance

    dimensions = {
      length: ..(dock.length - clearance[:length]),
      beam: ..(dock.beam - clearance[:beam]),
      height: ..(dock.height - clearance[:height])
    }

    # `size`, not `ground`: the latter means "cannot reach space", so a hover bike
    # is ground: false while still berthing as a vehicle. See Dock#fits?.
    if dock.for_vehicles?
      return scope.where(models: {size: ::Dock::VEHICLE_SIZE}.merge(dimensions))
    end

    # `where.not` drops a null size along with the vehicles, which is what we
    # want: the two models without one are planetary beacons.
    scope.where(models: dimensions).where.not(models: {size: ::Dock::VEHICLE_SIZE})
  end

  private def will_it_fit_carrier(slug)
    return if slug.blank?

    Model.visible.active
      .where(slug: slug)
      .or(Model.where(rsi_slug: slug))
      .or(Model.where(legacy_slug: slug))
      .first
  end
end
