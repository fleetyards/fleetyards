# frozen_string_literal: true

module Api
  module V1
    # The goods a contract asks for. Editing a line costs what editing the
    # contract costs -- `FleetContractItemPolicy` delegates rather than
    # re-deriving, so the two can never disagree.
    class FleetContractItemsController < ::Api::BaseController
      include FleetSubscriptionConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :set_fleet
      before_action :check_fleet_contracts_feature
      before_action -> { require_fleet_subscription(:contracts) }
      before_action :set_fleet_contract
      before_action :set_fleet_contract_item, only: %i[update destroy]

      def create
        @fleet_contract_item = @fleet_contract.fleet_contract_items.new(fleet_contract_item_params)

        authorize! @fleet_contract_item, context: {fleet_contract: @fleet_contract}

        if @fleet_contract_item.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_contract_items.create", errors: @fleet_contract_item.errors),
            status: :bad_request
        end
      end

      def update
        authorize! @fleet_contract_item, context: {fleet_contract: @fleet_contract}

        if @fleet_contract_item.update(fleet_contract_item_params)
          render :show
        else
          render json: ValidationError.new("fleet_contract_items.update", errors: @fleet_contract_item.errors),
            status: :bad_request
        end
      end

      def destroy
        authorize! @fleet_contract_item, context: {fleet_contract: @fleet_contract}

        unless @fleet_contract_item.destroy
          render json: ValidationError.new("fleet_contract_items.destroy", errors: @fleet_contract_item.errors),
            status: :bad_request
        end
      end

      private def fleet_contract_item_params
        authorized(params, with: FleetContractItemPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_fleet_contract
        @fleet_contract = @fleet.fleet_contracts.find_by!(slug: params[:fleet_contract_slug])
      end

      private def set_fleet_contract_item
        @fleet_contract_item = @fleet_contract.fleet_contract_items.find(params[:id])
      end

      private def check_fleet_contracts_feature
        return if feature_enabled?("fleet_contracts", @fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
