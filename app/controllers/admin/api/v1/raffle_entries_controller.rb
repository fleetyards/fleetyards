# frozen_string_literal: true

module Admin
  module Api
    module V1
      class RaffleEntriesController < ::Admin::Api::BaseController
        before_action :set_raffle

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.raffle"))
        end

        def index
          @entries = @raffle.entries
            .includes(:user)
            .order(Arel.sql("draw_position ASC NULLS LAST, created_at ASC"))
            .page(page_params)
            .per(per_page(RaffleEntry))
        end

        private def set_raffle
          @raffle = Raffle.find(params[:raffle_id])

          authorize! @raffle, with: ::Admin::RafflePolicy
        end
      end
    end
  end
end
