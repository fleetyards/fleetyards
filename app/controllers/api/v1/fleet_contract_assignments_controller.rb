# frozen_string_literal: true

module Api
  module V1
    # The crew. Asking to join needs no more than being able to see the board;
    # the lead decides who actually works the job.
    class FleetContractAssignmentsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create destroy accept decline]

      before_action :set_fleet
      before_action :check_fleet_contracts_feature
      before_action :set_fleet_contract
      before_action :set_fleet_contract_assignment, only: %i[destroy accept decline]

      def index
        authorize! with: FleetContractAssignmentPolicy, context: {fleet: @fleet, fleet_contract: @fleet_contract}

        @fleet_contract_assignments = @fleet_contract.fleet_contract_assignments
          .where.not(aasm_state: %w[withdrawn removed declined])
          .includes(:user)
          .order(:role, :created_at)
      end

      def create
        @fleet_contract_assignment = @fleet_contract.fleet_contract_assignments
          .find_or_initialize_by(user: current_resource_owner)

        authorize! @fleet_contract_assignment, to: :create?,
          context: {fleet: @fleet, fleet_contract: @fleet_contract}

        # Asking again after being turned down is a new request, not a second
        # row -- the unique index would refuse one anyway.
        @fleet_contract_assignment.role = :crew
        @fleet_contract_assignment.aasm_state = "requested"
        @fleet_contract_assignment.requested_at = Time.current

        if @fleet_contract_assignment.save
          ActiveSupport::Notifications.instrument("fleet_contract_assignment.requested",
            assignment: @fleet_contract_assignment)

          render :show, status: :created
        else
          render json: ValidationError.new("fleet_contract_assignments.create",
            errors: @fleet_contract_assignment.errors), status: :bad_request
        end
      end

      def accept
        authorize! @fleet_contract_assignment, to: :accept?,
          context: {fleet: @fleet, fleet_contract: @fleet_contract}

        @fleet_contract_assignment.approved_by = current_resource_owner

        unless @fleet_contract_assignment.accept!
          return render json: ValidationError.new("fleet_contract_assignments.accept",
            errors: @fleet_contract_assignment.errors), status: :bad_request
        end

        announce_answer
      end

      def decline
        authorize! @fleet_contract_assignment, to: :decline?,
          context: {fleet: @fleet, fleet_contract: @fleet_contract}

        @fleet_contract_assignment.approved_by = current_resource_owner

        unless @fleet_contract_assignment.decline!
          return render json: ValidationError.new("fleet_contract_assignments.decline",
            errors: @fleet_contract_assignment.errors), status: :bad_request
        end

        announce_answer
      end

      # Leaving, or being taken off. Which of the two it was is the state, not
      # the verb: the row is kept either way, because a contractor who delivered
      # something still has to be paid for it.
      def destroy
        authorize! @fleet_contract_assignment, to: :destroy?,
          context: {fleet: @fleet, fleet_contract: @fleet_contract}

        own = @fleet_contract_assignment.user_id == current_resource_owner&.id
        moved = own ? @fleet_contract_assignment.withdraw! : @fleet_contract_assignment.remove!

        unless moved
          return render json: ValidationError.new("fleet_contract_assignments.destroy",
            errors: @fleet_contract_assignment.errors), status: :bad_request
        end

        render :show
      end

      private def announce_answer
        ActiveSupport::Notifications.instrument("fleet_contract_assignment.answered",
          assignment: @fleet_contract_assignment)

        render :show
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_fleet_contract
        @fleet_contract = @fleet.fleet_contracts.find_by!(slug: params[:fleet_contract_slug])
      end

      private def set_fleet_contract_assignment
        @fleet_contract_assignment = @fleet_contract.fleet_contract_assignments.find(params[:id])
      end

      private def check_fleet_contracts_feature
        return if feature_enabled?("fleet_contracts", @fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
