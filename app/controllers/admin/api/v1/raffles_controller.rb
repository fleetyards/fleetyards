# frozen_string_literal: true

module Admin
  module Api
    module V1
      class RafflesController < ::Admin::Api::BaseController
        before_action :set_raffle, only: %i[show update destroy draw]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.raffle"))
        end

        def index
          authorize! with: ::Admin::RafflePolicy

          normalize_sort_params(raffle_query_params)
          raffle_query_params["sorts"] = sorting_params(Raffle, raffle_query_params[:sorts])

          q = Raffle.ransack(raffle_query_params)

          @raffles = q.result(distinct: true)
            .includes(:drawn_by, model: {store_image_attachment: :blob})
            .page(page_params)
            .per(per_page(Raffle))
        end

        def show
        end

        def create
          @raffle = Raffle.new(raffle_params)

          authorize! @raffle, with: ::Admin::RafflePolicy

          return if @raffle.save

          render json: ValidationError.new("raffle.create", errors: @raffle.errors), status: :bad_request
        end

        def update
          return if @raffle.update(raffle_params)

          render json: ValidationError.new("raffle.update", errors: @raffle.errors), status: :bad_request
        end

        def destroy
          return if @raffle.destroy

          render json: ValidationError.new("raffle.destroy", errors: @raffle.errors), status: :bad_request
        end

        def draw
          result = ::Raffles::Draw.new(@raffle, admin_user: current_admin_user).call

          unless result.status == :drawn
            return render json: ValidationError.new("raffle.draw", message: I18n.t("validation_error.raffle.messages.#{result.status}")), status: :bad_request
          end

          @raffle.reload
          render :show
        end

        private def set_raffle
          @raffle = Raffle.find(params[:id])

          authorize! @raffle, with: ::Admin::RafflePolicy
        end

        private def raffle_params
          @raffle_params ||= params.permit(
            :title, :description, :model_id, :code, :starts_at, :ends_at, :claim_period_days, :published
          )
        end

        private def raffle_query_params
          @raffle_query_params ||= params.permit(q: [
            :title_cont, :published_eq,
            :s, :sorts, s: [], sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
