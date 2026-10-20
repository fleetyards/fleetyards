# frozen_string_literal: true

module Admin
  module Api
    module V1
      class GameEventsController < ::Admin::Api::BaseController
        before_action :set_game_event, only: %i[show update destroy]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.game_event"))
        end

        def index
          authorize! with: ::Admin::GameEventPolicy

          normalize_sort_params(game_event_query_params)
          game_event_query_params["sorts"] = sorting_params(GameEvent, game_event_query_params[:sorts])

          q = GameEvent.ransack(game_event_query_params)

          @game_events = q.result(distinct: true)
            .page(page_params)
            .per(per_page(GameEvent))
        end

        def show
        end

        def create
          @game_event = GameEvent.new(game_event_params)

          authorize! @game_event, with: ::Admin::GameEventPolicy

          return if @game_event.save

          render json: ValidationError.new("game_event.create", errors: @game_event.errors), status: :bad_request
        end

        def update
          return if @game_event.update(game_event_params)

          render json: ValidationError.new("game_event.update", errors: @game_event.errors), status: :bad_request
        end

        def destroy
          return if @game_event.destroy

          render json: ValidationError.new("game_event.destroy", errors: @game_event.errors), status: :bad_request
        end

        private def set_game_event
          @game_event = GameEvent.find(params[:id])

          authorize! @game_event, with: ::Admin::GameEventPolicy
        end

        private def game_event_params
          @game_event_params ||= params.permit(
            :title, :description, :location, :url, :category, :starts_at, :ends_at, :published
          )
        end

        private def game_event_query_params
          @game_event_query_params ||= params.permit(q: [
            :title_cont, :category_eq, :published_eq,
            :starts_at_gteq, :starts_at_lteq,
            :s, :sorts, s: [], sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
