# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FleetsController < ::Admin::Api::BaseController
        before_action :set_fleet, only: %i[show update destroy revoke_rsi_verification]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          authorize! with: ::Admin::FleetPolicy

          normalize_sort_params(fleet_query_params)
          fleet_query_params["sorts"] = sorting_params(Fleet, fleet_query_params[:sorts], allowed: Fleet::ADMIN_SORTING_PARAMS)

          @q = Fleet.kept.with_member_count.ransack(fleet_query_params)

          @fleets = @q.result
            .includes(:fleet_roles)
            .page(page_params)
            .per(per_page(Fleet))
        end

        def show
        end

        def options
          authorize! with: ::Admin::FleetPolicy

          search = fleet_query_params.delete(:search).presence
          scope = Fleet.kept.with_member_count

          if search
            @fleets = scope.search_ranked(search)
              .page(page_params)
              .per(per_page(Fleet))
            return
          end

          fleet_query_params["sorts"] = "name asc"

          @q = scope.ransack(fleet_query_params)

          @fleets = @q.result(distinct: true)
            .page(page_params)
            .per(per_page(Fleet))
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
          return if @fleet.discard

          render json: ValidationError.new("fleet.destroy", errors: @fleet.errors), status: :bad_request
        end

        def revoke_rsi_verification
          @fleet.revoke_rsi_verification!

          render :show
        end

        private def set_fleet
          @fleet = Fleet.find(params[:id])

          authorize! @fleet, with: ::Admin::FleetPolicy
        end

        private def fleet_params
          @fleet_params ||= params.permit(
            :name, :fid, :description, :public_fleet, :public_fleet_stats,
            :discord, :guilded, :homepage, :twitch, :youtube, :ts,
            :rsi_sid, :logo, :background_image, :headquarters, :headquarters_location_id
          )
        end

        private def fleet_query_params
          @fleet_query_params ||= params.permit(q: [
            :name_cont, :fid_cont, :search,
            :member_count_gteq, :member_count_lteq, :rsi_verified_eq, :public_fleet_eq, :recruiting_eq,
            :created_on_gteq, :created_on_lteq,
            :s, :sorts, s: [], sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
