# frozen_string_literal: true

module Api
  module V1
    class RafflesController < ::Api::BaseController
      include RafflesFeatureConcern

      skip_before_action :authenticate_user!, only: %i[current show entrants]
      before_action :check_raffles_feature
      before_action :set_raffle, only: %i[show entrants]

      after_action -> { pagination_header(:entries) }, only: [:entrants]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.raffle"))
      end

      def current
        authorize! with: ::RafflePolicy

        @raffle = Raffle.current
        raise ActiveRecord::RecordNotFound if @raffle.blank?

        @viewer_entries = viewer_entries_for([@raffle.id])
        render :show
      end

      def show
        @viewer_entries = viewer_entries_for([@raffle.id])
      end

      def entrants
        @entries = @raffle.entries
          .includes(:user)
          .order(created_at: :desc)
          .page(page_params)
          .per(per_page(RaffleEntry))
      end

      private def viewer_entries_for(raffle_ids)
        return {} if current_resource_owner.blank?

        RaffleEntry.where(user: current_resource_owner, raffle_id: raffle_ids).index_by(&:raffle_id)
      end

      private def set_raffle
        @raffle = Raffle.published.find(params[:id])

        authorize! @raffle, with: ::RafflePolicy
      end
    end
  end
end
