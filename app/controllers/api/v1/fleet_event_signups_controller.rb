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

        target_status = requested_status_for(@slot.fleet_event, @slot, params[:status])

        # If the member already has an unassigned (interested/tentative) signup
        # for this event, promote it onto this slot rather than creating a new
        # one (which would fail unique-active-signup validation).
        existing = @slot.fleet_event.fleet_event_signups
          .where(fleet_membership_id: @membership.id)
          .where.not(status: "withdrawn")
          .first

        if existing && existing.fleet_event_slot_id.present? && existing.fleet_event_slot_id != @slot.id
          authorize! existing, with: FleetEventSignupPolicy, context: {fleet_event: @slot.fleet_event}, to: :create?
          render json: {code: "already_signed_up", message: "Already signed up to a different slot"}, status: :conflict
          return
        end

        if existing
          @signup = existing
          attrs = {
            fleet_event_slot_id: @slot.id,
            status: target_status,
            notes: params[:notes].presence || @signup.notes
          }
          attrs[:vehicle_id] = params[:vehicle_id] if params.key?(:vehicle_id)

          authorize! @signup, with: FleetEventSignupPolicy, context: {fleet_event: @slot.fleet_event}, to: :update?

          previous_status = @signup.status
          if @signup.update(attrs)
            event_name = (previous_status != @signup.status) ? "fleet_event_signup.status_changed" : "fleet_event_signup.created"
            ActiveSupport::Notifications.instrument(event_name, signup: @signup, previous_status: previous_status)
            render :show
          else
            render json: ValidationError.new("fleet_event_signups.create", errors: @signup.errors), status: :bad_request
          end
          return
        end

        @signup = @slot.fleet_event_signups.new(
          fleet_event: @slot.fleet_event,
          fleet_membership_id: @membership.id,
          status: target_status,
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

      # Sign up to the event without picking a slot. Acts as upsert: if the
      # member already has an unassigned signup, updates it (so they can switch
      # interested ↔ tentative ↔ confirmed without withdrawing first). If they
      # are already in a slot, returns 409 — they need to withdraw first.
      def event_signup
        if @membership.nil?
          render json: {code: "forbidden", message: "Not a fleet member"}, status: :forbidden
          return
        end

        requested_status =
          params[:status].presence&.then { |s| FleetEventSignup::MEMBER_REQUESTABLE_STATUSES.include?(s) ? s : "interested" } ||
          "interested"

        existing = @event.fleet_event_signups
          .where(fleet_membership_id: @membership.id)
          .where.not(status: "withdrawn")
          .first

        if existing && existing.fleet_event_slot_id.present?
          authorize! existing, with: FleetEventSignupPolicy, context: {fleet_event: @event}, to: :create?
          render json: {code: "already_signed_up", message: "Already signed up to a slot in this event"}, status: :conflict
          return
        end

        if existing
          @signup = existing
          authorize! @signup, with: FleetEventSignupPolicy, context: {fleet_event: @event}, to: :update?

          attrs = {status: requested_status}
          attrs[:notes] = params[:notes] if params.key?(:notes)
          attrs[:vehicle_id] = params[:vehicle_id] if params.key?(:vehicle_id)

          previous_status = @signup.status
          if @signup.update(attrs)
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
          return
        end

        @signup = @event.fleet_event_signups.new(
          fleet_membership_id: @membership.id,
          fleet_event_slot_id: nil,
          status: requested_status,
          vehicle_id: params[:vehicle_id],
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
        attrs = params.permit(:status, :vehicle_id, :notes, :fleet_event_slot_id).to_h.symbolize_keys
        # Slot-bound signups must be confirmed (or pending awaiting approval).
        # If an admin assigns a slot but doesn't override status, promote any
        # tentative/interested status to confirmed automatically.
        if attrs.key?(:fleet_event_slot_id) && attrs[:fleet_event_slot_id].present?
          current_status = attrs[:status].presence || @signup.status
          unless FleetEventSignup::SLOT_BOUND_STATUSES.include?(current_status)
            attrs[:status] = "confirmed"
          end
        end
        attrs
      end

      private def requested_status_for(event, slot, requested)
        requested = requested.presence || "confirmed"
        unless FleetEventSignup::MEMBER_REQUESTABLE_STATUSES.include?(requested)
          requested = "confirmed"
        end

        # Tentative/interested are event-level only — picking a slot is a
        # commitment, so coerce to confirmed.
        requested = "confirmed" if slot.present? && requested != "confirmed"

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
