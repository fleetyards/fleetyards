# frozen_string_literal: true

module Api
  module V1
    class FleetMembershipsController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.fleet', slug: params[:slug]))
      end

      def current
        authorize! :show, my_membership

        @member = my_membership
      end

      def create
        user = User.find_by!(normalized_username: params[:username].downcase)

        @member = fleet.fleet_memberships.new(user_id: user.id, role: :member, invited_by: current_user.id)

        authorize! :create, member

        if member.save
          member.invite!
        else
          render json: ValidationError.new('fleet_memberships.create', errors: member.errors), status: :bad_request
        end
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
          render json: ValidationError.new('fleet_memberships.create', errors: member.errors), status: :bad_request
        end
      end

      def update
        authorize! :update, my_membership

        return if my_membership.update(membeship_params)

        render json: ValidationError.new('fleet_memberships.update', errors: my_membership.errors), status: :bad_request
      end

      def accept_invite
        authorize! :accept_invitation, my_membership

        return if my_membership.accept_invitation!

        render json: ValidationError.new('fleet_memberships.accept', errors: my_membership.errors), status: :bad_request
      end

      def decline_invite
        authorize! :decline_invitation, my_membership

        return if my_membership.decline!

        render json: ValidationError.new('fleet_memberships.decline', errors: my_membership.errors), status: :bad_request
      end

      def accept_request
        authorize! :accept_request, member

        return if member.accept_request!

        render json: ValidationError.new('fleet_memberships.accept', errors: member.errors), status: :bad_request
      end

      def decline_request
        authorize! :accept_request, member

        return if member.decline!

        render json: ValidationError.new('fleet_memberships.decline', errors: member.errors), status: :bad_request
      end

      def promote
        authorize! :promote, member

        return if member.promote

        render json: ValidationError.new('fleet_memberships.promote', errors: member.errors), status: :bad_request
      end

      def demote
        authorize! :demote, member

        return if member.demote

        render json: ValidationError.new('fleet_memberships.demote', errors: member.errors), status: :bad_request
      end

      def destroy
        authorize! :destroy, member

        return if member.destroy

        render json: ValidationError.new('fleet_memberships.destroy', errors: member.errors), status: :bad_request
      end

      def leave
        authorize! :destroy, my_membership

        if my_membership.admin?
          render json: ValidationError.new('fleet_memberships.destroy', message: I18n.t('validation_error.fleet_memberships.destroy_as_admin')), status: :bad_request
          return
        end

        return if my_membership.destroy

        render json: ValidationError.new('fleet_memberships.destroy', errors: my_membership.errors), status: :bad_request
      end

      private def membeship_params
        @membeship_params ||= params.transform_keys(&:underscore)
          .permit(:primary, :ships_filter, :hangar_group_id)
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:fleet_slug]).first!
      end

      private def member
        @member ||= fleet.fleet_memberships
          .includes(:user)
          .joins(:user)
          .find_by!(normalized_username: params[:username].downcase)
      end

      private def my_membership
        @my_membership ||= fleet.fleet_memberships
          .includes(:user)
          .joins(:user)
          .where(user_id: current_user.id)
          .first!
      end
    end
  end
end
