module Public
  # What somebody outside a fleet may read of it.
  #
  # Three surfaces, each asked independently. `show?` admitting on
  # `public_fleet_stats?` is deliberate and predates this -- a fleet that
  # publishes only its numbers still has a page -- which is exactly why the ally
  # clause has to be added to each rule rather than to a shared helper: folding
  # them together would let `allies_fleet_stats` quietly open the fleet page too.
  class FleetPolicy < FleetBasePolicy
    def show?
      member? || record.public_fleet? || record.public_fleet_stats? ||
        open_to_allies?(:allies_fleet) || open_to_allies?(:allies_fleet_stats)
    end

    def show_stats?
      member? || record.public_fleet_stats? || open_to_allies?(:allies_fleet_stats)
    end

    # The roster has no public form -- see the migration. A member reads it
    # through the fleet's own endpoint; this is the ally's way in.
    def show_members?
      member? || open_to_allies?(:allies_fleet_members)
    end

    private def member?
      fleet_membership&.accepted? || false
    end

    private def open_to_allies?(setting)
      return false unless record.public_send(:"#{setting}?")

      allied?
    end

    # The reader stands in this through a fleet of their own, so the question is
    # whether any fleet they are an accepted member of is allied with this one.
    #
    # `accepted` is not optional: `User#fleets` follows kept memberships whatever
    # state they are in, so an unanswered invitation to an allied fleet would
    # otherwise be enough to read this one.
    private def allied?
      return false if reader_fleet_ids.empty?

      record.allies.exists?(id: reader_fleet_ids)
    end

    private def reader_fleet_ids
      @reader_fleet_ids ||= user&.fleet_memberships&.kept&.accepted&.pluck(:fleet_id) || []
    end
  end
end
