# frozen_string_literal: true

module Api
  module V1
    class FleetSquadronsController < ::Api::BaseController
      include FleetSquadronScoped

      after_action -> { pagination_header(:fleet_squadrons) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy]

      before_action :set_fleet
      before_action :check_fleet_squadrons_feature
      before_action :set_fleet_squadron, only: %i[show update destroy]

      def index
        authorize! with: FleetSquadronPolicy, context: {fleet: @fleet}

        scope = readable_fleet_squadrons.includes(:fleet_memberships, logo_attachment: :blob)

        query_params = params.fetch(:q, {}).permit(:name_cont, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(FleetSquadron, query_params["sorts"])

        @q = scope.ransack(query_params)

        @fleet_squadrons = result_with_pagination(@q.result(distinct: true), per_page(FleetSquadron))
      end

      def show
        authorize! @fleet_squadron
      end

      def create
        @fleet_squadron = @fleet.fleet_squadrons.new(fleet_squadron_params)

        authorize! @fleet_squadron

        if @fleet_squadron.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_squadrons.create", errors: @fleet_squadron.errors), status: :bad_request
        end
      end

      def update
        authorize! @fleet_squadron

        if @fleet_squadron.update(fleet_squadron_params)
          render :show
        else
          render json: ValidationError.new("fleet_squadrons.update", errors: @fleet_squadron.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @fleet_squadron

        unless @fleet_squadron.destroy
          render json: ValidationError.new("fleet_squadrons.destroy", errors: @fleet_squadron.errors), status: :bad_request
        end
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def fleet_squadron_params
        authorized(params, with: FleetSquadronPolicy, context: {fleet: @fleet})
      end
    end
  end
end
