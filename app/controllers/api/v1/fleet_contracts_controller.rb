# frozen_string_literal: true

module Api
  module V1
    class FleetContractsController < ::Api::BaseController
      after_action -> { pagination_header(:fleet_contracts) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show progress]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy publish claim release fulfil cancel]

      before_action :set_fleet
      before_action :check_fleet_contracts_feature
      before_action :set_fleet_contract,
        only: %i[show update destroy publish claim release fulfil cancel progress]

      def index
        authorize! with: FleetContractPolicy, context: {fleet: @fleet}

        scope = visible_scope

        query_params = params.fetch(:q, {}).permit(:title_cont, :state_eq, :kind_eq, :s, {state_in: []})
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(FleetContract, query_params["sorts"])

        @q = scope.ransack(query_params)

        @fleet_contracts = result_with_pagination(
          @q.result(distinct: true).includes(:destination_fleet_inventory, :source_fleet_inventory, :created_by),
          per_page(FleetContract)
        )
      end

      def show
        authorize! @fleet_contract
      end

      def create
        @fleet_contract = @fleet.fleet_contracts.new(fleet_contract_params)
        @fleet_contract.created_by = current_resource_owner

        authorize! @fleet_contract

        if @fleet_contract.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_contracts.create", errors: @fleet_contract.errors),
            status: :bad_request
        end
      end

      def update
        authorize! @fleet_contract

        if @fleet_contract.update(fleet_contract_params)
          render :show
        else
          render json: ValidationError.new("fleet_contracts.update", errors: @fleet_contract.errors),
            status: :bad_request
        end
      end

      def destroy
        authorize! @fleet_contract

        unless @fleet_contract.destroy
          render json: ValidationError.new("fleet_contracts.destroy", errors: @fleet_contract.errors),
            status: :bad_request
        end
      end

      def publish
        authorize! @fleet_contract

        return unless transition("publish") { @fleet_contract.publish! }

        ActiveSupport::Notifications.instrument("fleet_contract.published", contract: @fleet_contract)
      end

      def claim
        authorize! @fleet_contract

        unless @fleet_contract.claim_by(current_resource_owner)
          return render json: ValidationError.new("fleet_contracts.claim", errors: @fleet_contract.errors),
            status: :bad_request
        end

        ActiveSupport::Notifications.instrument("fleet_contract.claimed",
          contract: @fleet_contract, user: current_resource_owner)

        render :show
      end

      def release
        authorize! @fleet_contract

        unless @fleet_contract.release_to_board!
          return render json: ValidationError.new("fleet_contracts.release", errors: @fleet_contract.errors),
            status: :bad_request
        end

        render :show
      end

      # Forcing it early. The automatic path is `Contracts::Fulfilment`, run
      # when a linked transfer completes, and it announces itself there -- so
      # this announces its own.
      def fulfil
        authorize! @fleet_contract

        return unless transition("fulfil") { @fleet_contract.fulfil! }

        ActiveSupport::Notifications.instrument("fleet_contract.fulfilled", contract: @fleet_contract)
      end

      def cancel
        authorize! @fleet_contract

        transition("cancel") { @fleet_contract.cancel! }
      end

      def progress
        authorize! @fleet_contract, to: :progress?
      end

      # Everything the member may see. A draft is not an offer of work yet, so
      # it only lists for the people who could publish it -- the same rule
      # `FleetContractPolicy#show?` applies to a single one.
      private def visible_scope
        scope = @fleet.fleet_contracts

        return scope if allowed_to?(:manage?, @fleet, with: FleetContractPolicy)

        scope.where.not(aasm_state: "draft")
      end

      private def transition(action)
        if yield
          render :show
          true
        else
          render json: ValidationError.new("fleet_contracts.#{action}", errors: @fleet_contract.errors),
            status: :bad_request
          false
        end
      end

      private def fleet_contract_params
        authorized(params, with: FleetContractPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_fleet_contract
        @fleet_contract = @fleet.fleet_contracts.find_by!(slug: params[:slug])
      end

      private def check_fleet_contracts_feature
        return if feature_enabled?("fleet_contracts", @fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
