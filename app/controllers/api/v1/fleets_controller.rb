# frozen_string_literal: true

module Api
  module V1
    class FleetsController < ::Api::BaseController
      skip_verify_authorized only: %i[check find_by_invite]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! },
        unless: :user_signed_in?,
        only: %i[create]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show check invites my find_by_invite]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[update destroy]

      before_action :set_fleet, only: %i[show update destroy]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.fleet", slug: params[:slug]))
      end

      def invites
        authorize!

        @invites = current_resource_owner.fleet_memberships.where(aasm_state: %w[requested invited]).all
      end

      def my
        authorize!

        @fleets = authorized_scope(Fleet.all).accepted.all
      end

      def show
      end

      def create
        @fleet = Fleet.new(fleet_create_params.merge(created_by: current_user.id))

        authorize! @fleet

        if @fleet.save
          render :create, status: :created
        else
          render json: ValidationError.new("fleet.create", errors: @fleet.errors), status: :bad_request
        end
      end

      def update
        return if @fleet.update(fleet_params)

        render json: ValidationError.new("fleet.update", errors: @fleet.errors), status: :bad_request
      end

      def destroy
        return if @fleet.destroy

        render json: ValidationError.new("fleet.destroy", errors: @fleet.errors), status: :bad_request
      end

      def check
        render json: {taken: Fleet.exists?(normalized_fid: params.fetch(:value, "").downcase)}
      end

      def find_by_invite
        invite_url = FleetInviteUrl.active.find_by!(token: params[:token])

        @fleet = invite_url.fleet

        render "show"
      end

      private def set_fleet
        @fleet = Fleet.find_by!(slug: params[:slug])

        authorize! @fleet
      end

      private def fleet_create_params
        authorized(params, as: :create)
      end

      private def fleet_params
        authorized(params, context: {fleet: @fleet})
      end
    end
  end
end
