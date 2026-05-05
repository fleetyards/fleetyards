# frozen_string_literal: true

module Api
  module V1
    class FleetEventSignupsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :check_mission_builder_feature
      before_action :set_slot, only: %i[create update destroy_self]
      before_action :set_membership, only: %i[create update destroy_self]
      before_action :set_signup_for_self, only: %i[update destroy_self]
      before_action :set_signup_admin, only: %i[destroy]

      def create
        if @membership.nil?
          render json: {code: "forbidden", message: "Not a fleet member"}, status: :forbidden
          return
        end

        @signup = @slot.fleet_event_signups.new(
          fleet_membership_id: @membership.id,
          status: params[:status].presence || "confirmed",
          vehicle_id: params[:vehicle_id],
          notes: params[:notes]
        )

        authorize! @signup, with: FleetEventSignupPolicy, context: {fleet_event: @slot.fleet_event}

        if @signup.save
          ActiveSupport::Notifications.instrument("fleet_event_signup.created", signup: @signup)
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_event_signups.create", errors: @signup.errors), status: :bad_request
        end
      end

      def update
        authorize! @signup, with: FleetEventSignupPolicy, context: {fleet_event: @slot.fleet_event}

        previous_status = @signup.status
        if @signup.update(signup_attrs)
          if previous_status != @signup.status
            ActiveSupport::Notifications.instrument("fleet_event_signup.status_changed", signup: @signup, previous_status: previous_status)
          end
          render :show
        else
          render json: ValidationError.new("fleet_event_signups.update", errors: @signup.errors), status: :bad_request
        end
      end

      def destroy_self
        authorize! @signup, with: FleetEventSignupPolicy, context: {fleet_event: @slot.fleet_event}, to: :destroy?

        @signup.withdraw!
        ActiveSupport::Notifications.instrument("fleet_event_signup.withdrawn", signup: @signup)
        head :no_content
      end

      def destroy
        authorize! @signup, with: FleetEventSignupPolicy, context: {fleet_event: @signup.fleet_event}, to: :destroy?

        @signup.withdraw!
        ActiveSupport::Notifications.instrument("fleet_event_signup.withdrawn", signup: @signup)
        head :no_content
      end

      private def signup_attrs
        params.permit(:status, :vehicle_id, :notes)
      end

      private def set_slot
        @slot = FleetEventSlot.find(params[:id])
      end

      private def set_membership
        return if @slot.nil?

        @membership = current_resource_owner&.fleet_memberships&.find_by(
          fleet_id: @slot.fleet_event.fleet_id,
          aasm_state: "accepted"
        )
      end

      private def set_signup_for_self
        return if @membership.nil?

        @signup = @slot.fleet_event_signups
          .where(fleet_membership_id: @membership.id)
          .where.not(status: "withdrawn")
          .first

        if @signup.nil?
          render json: {code: "not_found", message: "Signup not found"}, status: :not_found
          nil
        end
      end

      private def set_signup_admin
        @signup = FleetEventSignup.find(params[:id])
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
