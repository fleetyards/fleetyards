# frozen_string_literal: true

module Api
  module V1
    class FleetEventSignupsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :check_mission_builder_feature
      before_action :set_slot, only: %i[create update destroy_self]
      before_action :set_event_for_event_signup, only: %i[event_signup]
      before_action :set_membership_for_slot, only: %i[create update destroy_self]
      before_action :set_membership_for_event, only: %i[event_signup]
      before_action :set_signup_for_self, only: %i[update destroy_self]
      before_action :set_signup_admin, only: %i[destroy update_admin]

      def create
        if @membership.nil?
          render json: {code: "forbidden", message: "Not a fleet member"}, status: :forbidden
          return
        end

        @signup = @slot.fleet_event_signups.new(
          fleet_event: @slot.fleet_event,
          fleet_membership_id: @membership.id,
          status: requested_status_for(@slot.fleet_event, @slot, params[:status]),
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

      # Sign up to the event without picking a slot. Always becomes an
      # `interested` signup; an admin can assign a slot later.
      def event_signup
        if @membership.nil?
          render json: {code: "forbidden", message: "Not a fleet member"}, status: :forbidden
          return
        end

        existing = @event.fleet_event_signups
          .where(fleet_membership_id: @membership.id)
          .where.not(status: "withdrawn")
          .first

        if existing
          render json: {code: "already_signed_up", message: "Already signed up to this event"}, status: :conflict
          return
        end

        @signup = @event.fleet_event_signups.new(
          fleet_membership_id: @membership.id,
          fleet_event_slot_id: nil,
          status: params[:status].presence&.then { |s| FleetEventSignup::MEMBER_REQUESTABLE_STATUSES.include?(s) ? s : "interested" } || "interested",
          notes: params[:notes]
        )

        authorize! @signup, with: FleetEventSignupPolicy, context: {fleet_event: @event}, to: :create?

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
        if @signup.update(self_signup_attrs)
          if previous_status != @signup.status
            ActiveSupport::Notifications.instrument("fleet_event_signup.status_changed", signup: @signup, previous_status: previous_status)
          end
          render :show
        else
          render json: ValidationError.new("fleet_event_signups.update", errors: @signup.errors), status: :bad_request
        end
      end

      # Admin endpoint — can reassign slot, change status (including approving
      # `pending` to `confirmed`), or update notes/vehicle.
      def update_admin
        authorize! @signup, with: FleetEventSignupPolicy,
          context: {fleet_event: @signup.fleet_event}, to: :manage?

        previous_status = @signup.status
        if @signup.update(admin_signup_attrs)
          if previous_status != @signup.status
            ActiveSupport::Notifications.instrument(
              "fleet_event_signup.status_changed",
              signup: @signup,
              previous_status: previous_status
            )
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

      # Member-side update params — never allow direct status promotion past
      # what their slot's approval mode allows.
      private def self_signup_attrs
        attrs = params.permit(:status, :vehicle_id, :notes).to_h.symbolize_keys
        if attrs[:status].present?
          attrs[:status] = requested_status_for(@signup.fleet_event, @signup.fleet_event_slot, attrs[:status])
        end
        attrs
      end

      private def admin_signup_attrs
        params.permit(:status, :vehicle_id, :notes, :fleet_event_slot_id)
      end

      private def requested_status_for(event, slot, requested)
        requested = requested.presence || "confirmed"
        unless FleetEventSignup::MEMBER_REQUESTABLE_STATUSES.include?(requested)
          requested = "confirmed"
        end

        approval = slot&.signup_approval.presence || event&.signup_approval || "direct"
        if approval == "confirmation_required" && requested == "confirmed"
          "pending"
        else
          requested
        end
      end

      private def set_slot
        @slot = FleetEventSlot.find(params[:id])
      end

      private def set_event_for_event_signup
        @fleet = Fleet.find_by!(slug: params[:fleet_slug])
        @event = @fleet.fleet_events.find_by!(slug: params[:slug])
      end

      private def set_membership_for_slot
        return if @slot.nil?

        @membership = current_resource_owner&.fleet_memberships&.find_by(
          fleet_id: @slot.fleet_event.fleet_id,
          aasm_state: "accepted"
        )
      end

      private def set_membership_for_event
        return if @event.nil?

        @membership = current_resource_owner&.fleet_memberships&.find_by(
          fleet_id: @event.fleet_id,
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
