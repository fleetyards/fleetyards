# frozen_string_literal: true

module Api
  module V1
    class FleetsController < ::Api::BaseController
      before_action :authenticate_user!, except: %i[show]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.fleet', slug: params[:slug]))
      end

      def invites
        authorize! :invites, :api_fleet

        @invites = current_user.fleet_memberships.where(aasm_state: %w[requested invited]).all
      end

      def current
        authorize! :read, :api_fleet

        @fleets = current_user.fleets.accepted.all
      end

      def show
        authorize! :read, :api_fleet
        @fleet = Fleet.where(slug: params[:slug]).first!
      end

      def create
        @fleet = Fleet.new(fleet_params.merge(created_by: current_user.id))
        authorize! :create, fleet

        return if fleet.save

        render json: ValidationError.new('fleet.create', errors: fleet.errors), status: :bad_request
      end

      def update
        authorize! :update, fleet

        return if fleet.update(fleet_params)

        render json: ValidationError.new('fleet.update', errors: fleet.errors), status: :bad_request
      end

      def destroy
        authorize! :destroy, fleet

        return if fleet.destroy

        render json: ValidationError.new('fleet.destroy', errors: fleet.errors), status: :bad_request
      end

      def check
        authorize! :check, :api_fleet
        render json: { taken: Fleet.exists?(fid: (fleet_params[:fid] || '').downcase) }
      end

      def find_by_invite
        authorize! :check, :api_fleet

        invite_url = FleetInviteUrl.active.find_by!(token: params[:token])

        @fleet = invite_url.fleet

        render 'show'
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:slug]).first!
      end

      private def fleet_params
        @fleet_params ||= params.transform_keys(&:underscore)
          .permit(
            :fid, :name, :description, :logo, :background_image, :public_fleet, :remove_logo,
            :remove_background, :homepage, :rsi_sid, :discord, :ts, :youtube,
            :twitch, :guilded
          )
      end
    end
  end
end
