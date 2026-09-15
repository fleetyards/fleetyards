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
        only: %i[create update destroy unarchive publish]

      before_action :set_fleet
      before_action :check_fleet_mission_builder_feature
      before_action :set_mission, only: %i[show update destroy unarchive publish]

      def index
        authorize! with: MissionPolicy, context: {fleet: @fleet}

        scope = visible_scope
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

        if save_mission
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

      # A draft is written by the create button and finished in the editor; this
      # is the step that offers it to the fleet.
      def publish
        authorize! @mission

        if @mission.publish!
          render :show
        else
          render json: ValidationError.new("missions.publish", errors: @mission.errors), status: :bad_request
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationError.new("missions.publish", errors: e.record.errors), status: :bad_request
      end

      def destroy
        authorize! @mission

        # Nothing was ever announced and nobody can have signed up, so a draft
        # goes rather than being archived -- abandoning a create leaves no trace.
        if @mission.archived? || @mission.draft?
          unless @mission.destroy
            render json: ValidationError.new("missions.destroy", errors: @mission.errors), status: :bad_request
          end
        elsif @mission.archive!
          render :show
        else
          render json: ValidationError.new("missions.destroy", errors: @mission.errors), status: :bad_request
        end
      end

      def unarchive
        authorize! @mission, to: :unarchive?

        if @mission.unarchive!
          render :show
        else
          render json: ValidationError.new("missions.unarchive", errors: @mission.errors), status: :bad_request
        end
      end

      # Everything the member may see. A draft is not a mission the fleet has
      # been offered yet, so it only lists for its author and for the people who
      # could publish it.
      private def visible_scope
        scope = @fleet.missions

        scope.visible_to(
          current_resource_owner,
          manage: allowed_to?(:manage?, Mission, context: {fleet: @fleet})
        )
      end

      # Two create buttons pressed at once settle on the same free title, and the
      # unique index on (fleet_id, slug) refuses the loser. A second attempt now
      # sees the winner's row and numbers past it rather than 500ing.
      private def save_mission(attempts: 2)
        @mission.save
      rescue ActiveRecord::RecordNotUnique
        raise if (attempts -= 1) <= 0

        @mission.slug = nil
        @mission.title = nil
        retry
      end

      private def mission_params
        authorized(params, with: MissionPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_mission
        # Through the same scope the list uses. Resolving from every mission in
        # the fleet would hand a draft to anybody who learned its slug, which is
        # exactly what keeping it off the list is meant to prevent.
        @mission = visible_scope.find_by!(slug: params[:slug])
      end

      private def check_fleet_mission_builder_feature
        return if feature_enabled?("fleet_mission_builder", @fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
