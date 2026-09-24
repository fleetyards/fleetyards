# frozen_string_literal: true

# Whether the reader may see a fleet's squadrons, asked once per fleet a
# request renders. A roster is one fleet, but the reader's own memberships list
# spans several, and each member row asks.
#
# The rows themselves are cached for every reader alike, so the squadrons are
# rendered outside the fragment and this is what decides whether they are.
module SquadronReadableConcern
  extend ActiveSupport::Concern

  included do
    helper SquadronHelper
  end

  def squadrons_readable_in?(fleet_id)
    @squadrons_readable ||= {}

    return @squadrons_readable[fleet_id] if @squadrons_readable.key?(fleet_id)

    membership = current_resource_owner&.fleet_memberships&.kept&.accepted&.find_by(fleet_id:)

    @squadrons_readable[fleet_id] = membership&.has_access?(FleetSquadron::READ_PRIVILEGES) || false
  end
end
