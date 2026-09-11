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
    docks = carrier.docks.select { |dock| dock.berth? && dock.measured? }

    # A carrier nobody measured cannot answer, and filtering everything away
    # would state that nothing fits.
    return scope if docks.blank?

    # Both branches are built from `scope` so they stay the same class and stay
    # structurally compatible. `or` demands both and refuses a bare Hash, which
    # is what the hangar used to hand it.
    docks.map { |dock| dock_branch(scope, dock) }
      .reduce { |combined, branch| combined.or(branch) }
  end

  private def dock_branch(scope, dock)
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
      return scope.where(models: {size: ::Dock::VEHICLE_SIZE}.merge(dimensions))
    end

    # `where.not` drops a null size along with the vehicles, which is what we
    # want: the two models without one are planetary beacons.
    scope.where(models: dimensions).where.not(models: {size: ::Dock::VEHICLE_SIZE})
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
