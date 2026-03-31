# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FleetsController < ::Admin::Api::BaseController
        before_action :set_fleet, only: %i[show update destroy]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          authorize! with: ::Admin::FleetPolicy

          fleet_query_params["sorts"] = sorting_params(Fleet, fleet_query_params[:sorts])

          @q = Fleet.all.ransack(fleet_query_params)

          @fleets = @q.result
            .page(params[:page])
            .per(per_page(Fleet))
        end

        def show
        end

        def create
          @fleet = Fleet.new(fleet_params)

          authorize! @fleet, with: ::Admin::FleetPolicy

          return if @fleet.save

          render json: ValidationError.new("fleet.create", errors: @fleet.errors), status: :bad_request
        end

        def update
          return if @fleet.update(fleet_params)

          render json: ValidationError.new("fleet.update", errors: @fleet.errors), status: :bad_request
        end

        def destroy
          return if @fleet.destroy

          render json: ValidationError.new("fleet.destroy", errors: @fleet.errors), status: :bad_request
        end

        private def set_fleet
          @fleet = Fleet.find(params[:id])

          authorize! @fleet, with: ::Admin::FleetPolicy
        end

        private def fleet_params
          @fleet_params ||= params.permit(
            :name, :fid, :description, :public_fleet, :public_fleet_stats,
            :discord, :guilded, :homepage, :twitch, :youtube, :ts,
            :rsi_sid, :logo, :background_image
          )
        end

        private def fleet_query_params
          @fleet_query_params ||= params.permit(q: [
            :name_cont, :fid_cont, :sorts, sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
