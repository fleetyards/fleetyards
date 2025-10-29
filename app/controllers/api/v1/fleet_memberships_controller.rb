# frozen_string_literal: true

module Api
  module V1
    class FleetMembershipsController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |exception|
        not_found(I18n.t("messages.record_not_found.#{exception.model.downcase}", slug: params[:slug]))
      end

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! },
        unless: :user_signed_in?,
        only: %i[show create_by_invite accept_invitation decline_invitation update destroy]

      before_action :set_fleet, only: %i[create show update accept_invitation decline_invitation destroy]
      before_action :set_membership, only: %i[show update accept_invitation decline_invitation destroy]

      def show
        @member = @membership
      end

      def create_by_invite
        invite_url = FleetInviteUrl.active.find_by!(token: params[:token])
        user = User.find_by!(normalized_username: params[:username].downcase)

        @member = invite_url.fleet.fleet_memberships.new(user_id: user.id, role: :member, invited_by: invite_url.user_id, used_invite_token: invite_url.token)

        authorize! :create_by_invite, member

        if member.save
          member.request!
          invite_url.reduce_limit
        else
          render json: ValidationError.new("fleet_memberships.create", errors: member.errors), status: :bad_request
        end
      end

      def update
        return if @membership.update(membership_params)

        render json: ValidationError.new("fleet_memberships.update", errors: @membership.errors), status: :bad_request
      end

      def accept_invitation
        unless @membership.accept_invitation!
          render json: ValidationError.new("fleet_memberships.accept", errors: @membership.errors), status: :bad_request
        end
      end

      def decline_invitation
        unless @membership.decline!
          render json: ValidationError.new("fleet_memberships.decline", errors: @membership.errors), status: :bad_request
        end
      end

      def destroy
        return if @membership.destroy

        render json: ValidationError.new("fleet_memberships.destroy", errors: @membership.errors), status: :bad_request
      end

      private def membership_params
        authorized(params, context: {fleet: @fleet})
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show_for_membership?
      end

      private def set_membership
        @membership = @fleet.fleet_memberships
          .includes(:user)
          .joins(:user)
          .find_by!(user_id: current_resource_owner.id)

        authorize! @membership
      end
    end
  end
end
