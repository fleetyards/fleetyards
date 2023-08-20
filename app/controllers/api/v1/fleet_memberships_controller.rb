# frozen_string_literal: true

module Api
  module V1
    class FleetMembershipsController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |exception|
        not_found(I18n.t("messages.record_not_found.#{exception.model.downcase}", slug: params[:slug]))
      end

      def show
        authorize! :show, membership
      end

      def update
        authorize! :update, membership

        return if membership.update(membership_params)

        render json: ValidationError.new("fleet_memberships.update", errors: membership.errors), status: :bad_request
      end

      def accept
        authorize! :accept_invitation, membership

        unless membership.accept_invitation
          render json: ValidationError.new("fleet_memberships.accept", errors: membership.errors), status: :bad_request
        end
      end

      def decline
        authorize! :decline_invitation, membership

        unless membership.decline
          render json: ValidationError.new("fleet_memberships.decline", errors: membership.errors), status: :bad_request
        end
      end

      def destroy
        authorize! :destroy, membership

        if membership.admin?
          render json: ValidationError.new("fleet_memberships.destroy", message: I18n.t("validation_error.fleet_memberships.leave_as_admin")), status: :bad_request
          return
        end

        return if membership.destroy

        render json: ValidationError.new("fleet_memberships.destroy", errors: membership.errors), status: :bad_request
      end

      private def membership_params
        @membership_params ||= params.transform_keys(&:underscore)
          .permit(:primary, :ships_filter, :hangar_group_id)
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:fleet_slug]).first!
      end

      private def membership
        @membership ||= fleet.fleet_memberships
          .includes(:user)
          .joins(:user)
          .where(user_id: current_user.id)
          .first!
      end
    end
  end
end
