# frozen_string_literal: true

module Api
  module V1
    class FleetRsiVerificationsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create check]

      before_action :set_fleet

      def show
      end

      # Rotates the token too: a token that leaked would otherwise let whoever
      # holds it verify their own fleet from the same org page.
      def create
        @fleet.generate_rsi_verification_token!

        render :show, status: :created
      end

      # A check inside the cooldown answers with the state as it is, so a
      # second click is not an error, just not another request to RSI.
      def check
        if @fleet.rsi_sid.blank? || @fleet.rsi_verification_token.blank?
          render json: ValidationError.new("fleet_rsi_verification.check"), status: :bad_request
          return
        end

        unless @fleet.rsi_verification_cooling_down?
          # rubocop:disable Rails/SkipsModelValidations
          @fleet.update_columns(
            rsi_verification_status: :pending,
            rsi_verification_checked_at: Time.current,
            updated_at: Time.current
          )
          # rubocop:enable Rails/SkipsModelValidations

          FleetRsiVerificationJob.perform_async(@fleet.id)
        end

        render :show
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :manage_rsi_verification?
      end
    end
  end
end
