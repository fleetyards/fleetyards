# frozen_string_literal: true

module Api
  module V1
    class RafflesController < ::Api::BaseController
      include RafflesFeatureConcern

      skip_before_action :authenticate_user!, only: %i[index show entrants]
      before_action :check_raffles_feature
      before_action :set_raffle, only: %i[show entrants claim code]

      after_action -> { pagination_header(:raffles) }, only: [:index]
      after_action -> { pagination_header(:entries) }, only: [:entrants]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.raffle"))
      end

      def index
        authorize! with: ::RafflePolicy

        @raffles = authorized_scope(Raffle.all, with: ::RafflePolicy)
          .includes(won_entries: :user, model: {store_image_attachment: :blob})
          .order(ends_at: :desc)
          .page(page_params)
          .per(per_page(Raffle))
        @viewer_entries = viewer_entries_for(@raffles.map(&:id))
        @entries_counts = RaffleEntry.where(raffle_id: @raffles.map(&:id)).group(:raffle_id).count
      end

      def show
        @viewer_entries = viewer_entries_for([@raffle.id])
      end

      def entrants
        @entries = @raffle.entries
          .includes(:user)
          .order(:created_at)
          .page(page_params)
          .per(per_page(RaffleEntry))
      end

      def claim
        unless @winning_entry.claim!
          return render json: ValidationError.new("raffle.claim", message: I18n.t("validation_error.raffle.messages.claim_expired")), status: :bad_request
        end

        render json: {code: @raffle.code}
      end

      # The code again, for a winner who claimed it already.
      def code
        if @winning_entry.claimed_at.blank?
          return render json: ValidationError.new("raffle.code", message: I18n.t("validation_error.raffle.messages.not_claimed")), status: :bad_request
        end

        render json: {code: @raffle.code}
      end

      private def viewer_entries_for(raffle_ids)
        return {} if current_resource_owner.blank?

        RaffleEntry.where(user: current_resource_owner, raffle_id: raffle_ids).index_by(&:raffle_id)
      end

      private def set_raffle
        @raffle = Raffle.published.find(params[:id])

        authorize! @raffle, with: ::RafflePolicy
        @winning_entry = @raffle.current_winner if %w[claim code].include?(action_name)
      end
    end
  end
end
