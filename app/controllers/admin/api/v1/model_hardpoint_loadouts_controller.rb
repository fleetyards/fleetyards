# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelHardpointLoadoutsController < ::Admin::Api::BaseController
        before_action :set_model_hardpoint_loadout, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::ModelHardpointLoadoutPolicy

          @q = authorized_scope(ModelHardpointLoadout.includes(:component, :model_hardpoint)).ransack(loadout_query_params)

          @model_hardpoint_loadouts = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          @model_hardpoint_loadout = ModelHardpointLoadout.new(loadout_params)

          authorize! @model_hardpoint_loadout, with: ::Admin::ModelHardpointLoadoutPolicy

          if @model_hardpoint_loadout.save
            render :show, status: :created
          else
            render json: ValidationError.new("model_hardpoint_loadout.create", errors: @model_hardpoint_loadout.errors), status: :bad_request
          end
        end

        def show
        end

        def update
          if @model_hardpoint_loadout.update(loadout_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("model_hardpoint_loadout.update", errors: @model_hardpoint_loadout.errors), status: :bad_request
          end
        end

        def destroy
          @model_hardpoint_loadout.destroy

          head :no_content
        end

        private def set_model_hardpoint_loadout
          @model_hardpoint_loadout = ModelHardpointLoadout.find(params[:id])

          authorize! @model_hardpoint_loadout, with: ::Admin::ModelHardpointLoadoutPolicy
        end

        private def loadout_params
          @loadout_params ||= params.permit(
            :name, :component_id, :model_hardpoint_id
          )
        end

        private def loadout_query_params
          @loadout_query_params ||= params.permit(q: [
            :model_hardpoint_id_eq, :name_cont, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end
