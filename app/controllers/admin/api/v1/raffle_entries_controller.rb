# frozen_string_literal: true

module Admin
  module Api
    module V1
      class RaffleEntriesController < ::Admin::Api::BaseController
        before_action :set_raffle
        before_action :set_entry, only: %i[send_verification claim]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.raffle"))
        end

        def index
          @entries = @raffle.entries
            .includes(:user, :claimed_by)
            .order(Arel.sql("draw_position ASC NULLS LAST, created_at ASC"))
            .page(page_params)
            .per(per_page(RaffleEntry))
        end

        def send_verification
          code = @entry.issue_verification_code!

          if code.nil?
            return render json: ValidationError.new("raffle_entry.send_verification", message: I18n.t("validation_error.raffle_entry.messages.verification_not_sent")), status: :bad_request
          end

          # Sent now rather than queued: a queued mail would carry the code in
          # its job arguments, readable in Redis until it is delivered.
          RaffleMailer.verification_code(@entry, code).deliver_now

          render json: {message: I18n.t("messages.raffle_entry.verification_sent", email: @entry.masked_email)}
        end

        def claim
          result = @entry.verify_and_claim!(params.require(:verification_code), admin_user: current_admin_user)

          unless result == :claimed
            return render json: ValidationError.new("raffle_entry.claim", message: I18n.t("validation_error.raffle_entry.messages.#{result}")), status: :bad_request
          end

          render json: {code: @raffle.code}
        end

        private def set_raffle
          @raffle = Raffle.find(params[:raffle_id])

          authorize! @raffle, with: ::Admin::RafflePolicy
        end

        private def set_entry
          @entry = @raffle.entries.find(params[:id])
        end
      end
    end
  end
end
