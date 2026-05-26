# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelSnubCraftsController < ::Admin::Api::BaseController
        before_action :set_model_snub_craft, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::ModelSnubCraftPolicy

          @q = authorized_scope(ModelSnubCraft.includes(:model, :snub_craft)).ransack(snub_craft_query_params)

          @model_snub_crafts = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          @model_snub_craft = ModelSnubCraft.new(snub_craft_params)

          authorize! @model_snub_craft, with: ::Admin::ModelSnubCraftPolicy

          if @model_snub_craft.save
            render :show, status: :created
          else
            render json: ValidationError.new("model_snub_craft.create", errors: @model_snub_craft.errors), status: :bad_request
          end
        end

        def show
        end

        def update
          if @model_snub_craft.update(snub_craft_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("model_snub_craft.update", errors: @model_snub_craft.errors), status: :bad_request
          end
        end

        def destroy
          @model_snub_craft.destroy

          head :no_content
        end

        private def set_model_snub_craft
          @model_snub_craft = ModelSnubCraft.find(params[:id])

          authorize! @model_snub_craft, with: ::Admin::ModelSnubCraftPolicy
        end

        private def snub_craft_params
          @snub_craft_params ||= params.permit(
            :model_id, :snub_craft_id
          )
        end

        private def snub_craft_query_params
          @snub_craft_query_params ||= params.permit(q: [
            :model_id_eq, :snub_craft_id_eq, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end
