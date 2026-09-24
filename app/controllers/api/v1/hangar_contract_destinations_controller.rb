# frozen_string_literal: true

module Api
  module V1
    # Where the caller can deliver as contract work: the destination of every
    # contract they hold an accepted seat on and that is still being worked.
    #
    # A destination held by somebody else -- a contract author's own inventory
    # -- is offered by name only. Naming it on a transfer is the one thing it is
    # good for, and even that only under this contract.
    class HangarContractDestinationsController < ::Api::BaseController
      include InventoryTransfersFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?

      before_action :check_inventory_transfers_feature

      def index
        authorize! with: HangarInventoryPolicy, to: :index?

        fleet_ids = current_resource_owner.fleet_memberships.kept.accepted.select(:fleet_id)

        contracts = ::FleetContract.in_progress
          .worked_by(current_resource_owner)
          .where(fleet_id: fleet_ids)
          .includes(:fleet, :destination_fleet_inventory, :destination_inventory, :fleet_contract_items)
          .order(:created_at)

        @targets = contracts.select do |contract|
          contract.destination.present? &&
            contract.destination_party != current_resource_owner &&
            feature_enabled?("fleet_contracts", contract.fleet)
        end
      end
    end
  end
end
