# frozen_string_literal: true

module Api
  module V1
    class RaffleClaimsController < ::Api::PublicBaseController
      skip_verify_authorized

      def create
        @entry = RaffleEntry.find_by_token_for(:raffle_claim, params[:token].to_s)

        if @entry.blank?
          return render json: ValidationError.new("raffle_claim.create", message: I18n.t("validation_error.raffle_claim.invalid")), status: :bad_request
        end

        if @entry.claim!
          Raffles::PrizeMailJob.perform_async(@entry.id)
        elsif @entry.claimed_at.blank?
          return render json: ValidationError.new("raffle_claim.create", message: I18n.t("validation_error.raffle_claim.expired")), status: :bad_request
        end

        # A second click lands here too and reads as success: the mail with the
        # code is already on its way, and saying otherwise would worry the winner.
        render status: :created
      end
    end
  end
end
