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
        only: %i[show create_by_invite update destroy]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        except: %i[create accept decline]

      def show
        authorize! :show, membership

        @member = membership
      end

      def create
        user = User.find_by!(normalized_username: params[:username].downcase)

        @member = fleet.fleet_memberships.new(user_id: user.id, role: :member, invited_by: current_user.id)

        authorize! :create, member

        if member.save
          member.invite!
        else
          render json: ValidationError.new("fleet_memberships.create", errors: member.errors), status: :bad_request
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
          render json: ValidationError.new("fleet_memberships.create", errors: member.errors), status: :bad_request
        end
      end

      def update
        authorize! :update, membership

        return if membership.update(membership_params)

        render json: ValidationError.new("fleet_memberships.update", errors: membership.errors), status: :bad_request
      end

      def accept
        authorize! :accept_invitation, membership

        unless membership.accept_invitation!
          render json: ValidationError.new("fleet_memberships.accept", errors: membership.errors), status: :bad_request
        end
      end

      def decline
        authorize! :decline_invitation, membership

        unless membership.decline!
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
