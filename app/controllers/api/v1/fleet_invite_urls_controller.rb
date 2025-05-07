# frozen_string_literal: true

module Api
  module V1
    class FleetInviteUrlsController < ::Api::BaseController
      after_action -> { pagination_header(:fleet_invite_urls) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! },
        unless: :user_signed_in?,
        only: %i[use]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create destroy]

      before_action :set_fleet, only: %i[index create destroy]
      before_action :set_fleet_invite_url, only: %i[destroy]

      def index
        authorize! with: FleetInviteUrlPolicy, context: {fleet: @fleet}

        scope = authorized_scope(FleetInviteUrl.all)

        scope.order(created_at: :desc)

        @fleet_invite_urls = scope
          .page(params[:page])
          .per(per_page(FleetInviteUrl))
      end

      def create
        @fleet_invite_url = @fleet.fleet_invite_urls.new(
          expires_after: expires_after_minutes,
          limit: fleet_invite_url_params[:limit],
          user_id: current_user.id
        )

        authorize! @fleet_invite_url

        if @fleet_invite_url.save
          render :create, status: :created
        else
          render json: ValidationError.new("fleet_invite_urls.create", errors: @fleet_invite_url.errors), status: :bad_request
        end
      end

      def destroy
        unless @fleet_invite_url.destroy
          render json: ValidationError.new("fleet_invite_urls.destroy", errors: @fleet_invite_url.errors), status: :bad_request
        end
      end

      def use
        invite_url = FleetInviteUrl.active.find_by!(token: params[:token])

        authorize! invite_url

        @membership = invite_url.fleet.fleet_memberships.new(
          user: current_user,
          fleet_role: invite_url.fleet.fleet_roles.ranked.last,
          invited_by: invite_url.user_id,
          used_invite_token: invite_url.token
        )

        if @membership.save
          @membership.request!
          invite_url.reduce_limit

          render "api/v1/fleet_memberships/show", status: :created
        else
          render json: ValidationError.new("fleet_memberships.create", errors: @membership.errors), status: :bad_request
        end
      end

      private def expires_after_minutes
        return if fleet_invite_url_params[:expires_after_minutes].blank?

        Time.zone.now + fleet_invite_url_params[:expires_after_minutes].to_i.minutes
      end

      private def fleet_invite_url_params
        authorized(params)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_fleet_invite_url
        @fleet_invite_url = @fleet.fleet_invite_urls.find_by!(token: params[:token])

        authorize! @fleet_invite_url
      end
    end
  end
end
