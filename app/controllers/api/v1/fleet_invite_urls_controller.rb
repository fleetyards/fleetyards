# frozen_string_literal: true

module Api
  module V1
    class FleetInviteUrlsController < ::Api::BaseController
      after_action -> { pagination_header(:fleet_invite_urls) }, only: %i[index]

      def index
        authorize! :show, fleet

        scope = fleet.fleet_invite_urls

        scope.order(created_at: :desc)

        @fleet_invite_urls = scope
          .page(params[:page])
          .per(per_page(FleetInviteUrl))
      end

      def create
        @fleet_invite_url = fleet.fleet_invite_urls.new(
          expires_after: expires_after_minutes,
          limit: fleet_invite_url_params[:limit],
          user_id: current_user.id
        )

        authorize! :create, fleet_invite_url

        return if fleet_invite_url.save

        render json: ValidationError.new("fleet_invite_urls.create", errors: fleet_invite_url.errors), status: :bad_request
      end

      def destroy
        @fleet_invite_url = fleet.fleet_invite_urls.find_by!(token: params[:token])

        authorize! :destroy, fleet_invite_url

        if fleet_invite_url.destroy
          render json: nil, status: :ok
        else
          render json: ValidationError.new("fleet_invite_urls.destroy", errors: fleet_invite_url.errors), status: :bad_request
        end
      end

      def use
        invite_url = FleetInviteUrl.active.find_by!(token: params[:token])

        @membership = invite_url.fleet.fleet_memberships.new(
          user: current_user,
          role: :member,
          invited_by: invite_url.user_id,
          used_invite_token: invite_url.token
        )

        authorize! :create_by_invite, @membership

        if @membership.save
          @membership.request!
          invite_url.reduce_limit

          render "api/v1/fleet_memberships/show", status: :created
        else
          render json: ValidationError.new("fleet_memberships.create", errors: @membership.errors), status: :bad_request
        end
      end

      private def fleet_invite_url
        @fleet_invite_url ||= fleet.fleet_invite_urls
          .where(token: params[:token])
          .first!
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:fleet_slug]).first!
      end

      private def expires_after_minutes
        return if fleet_invite_url_params[:expires_after_minutes].blank?

        Time.zone.now + fleet_invite_url_params[:expires_after_minutes].to_i.minutes
      end

      private def fleet_invite_url_params
        @fleet_invite_url_params ||= params.transform_keys(&:underscore)
          .permit(:fleet_slug, :limit, :expires_after_minutes)
      end
    end
  end
end
