# frozen_string_literal: true

module Api
  module V1
    # What the contract form offers as a destination: the fleet inventories the
    # caller could accept deliveries into, and the caller's own inventories.
    # The same answer the model checks a chosen destination against.
    class FleetContractDestinationsController < ::Api::BaseController
      include FleetSubscriptionConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?

      before_action :set_fleet
      before_action :check_fleet_contracts_feature
      before_action -> { require_fleet_subscription(:contracts) }

      def index
        authorize! with: FleetContractPolicy, to: :choose_destination?, context: {fleet: @fleet}

        options = ::Contracts::DestinationOptions.new(fleet: @fleet, editor: current_resource_owner,
          author: contract_author)

        @destinations = options.fleet_inventories + options.hangar_inventories
      end

      # Editing an existing contract, the hangar half is the author's and only
      # theirs to pick: anybody else is offered none of their own, which the
      # model would refuse. Unscoped, the caller is writing a new contract and
      # is its author.
      private def contract_author
        slug = params[:contract_slug] || params[:contractSlug]
        return current_resource_owner if slug.blank?

        @fleet.fleet_contracts.find_by!(slug:).created_by
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def check_fleet_contracts_feature
        return if feature_enabled?("fleet_contracts", @fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
