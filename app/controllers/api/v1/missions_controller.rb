# frozen_string_literal: true

module Api
  module V1
    class MissionsController < ::Api::BaseController
      after_action -> { pagination_header(:missions) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy]

      before_action :check_mission_builder_feature
      before_action :set_fleet
      before_action :set_mission, only: %i[show update destroy]

      def index
        authorize! with: MissionPolicy, context: {fleet: @fleet}

        scope = @fleet.missions
        scope = (params[:archived] == "true") ? scope.archived : scope.active

        query_params = params.fetch(:q, {}).permit(:title_cont, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(Mission, query_params["sorts"])

        @q = scope.ransack(query_params)
        result = @q.result(distinct: true)

        @missions = result_with_pagination(result, per_page(Mission))
      end

      def show
        authorize! @mission
      end

      def create
        @mission = @fleet.missions.new(mission_params)
        @mission.created_by = current_resource_owner

        authorize! @mission

        if @mission.save
          render :show, status: :created
        else
          render json: ValidationError.new("missions.create", errors: @mission.errors), status: :bad_request
        end
      end

      def update
        authorize! @mission

        if @mission.update(mission_params)
          render :show
        else
          render json: ValidationError.new("missions.update", errors: @mission.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @mission

        if @mission.archived?
          unless @mission.destroy
            render json: ValidationError.new("missions.destroy", errors: @mission.errors), status: :bad_request
          end
        elsif @mission.archive!
          render :show
        else
          render json: ValidationError.new("missions.destroy", errors: @mission.errors), status: :bad_request
        end
      end

      private def mission_params
        authorized(params, with: MissionPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_mission
        @mission = @fleet.missions.find_by!(slug: params[:slug])
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
