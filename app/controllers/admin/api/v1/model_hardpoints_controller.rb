# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelHardpointsController < ::Admin::Api::BaseController
        before_action :set_hardpoint, only: %i[show update destroy]

        def index
          if hardpoints_v2?
            authorize! with: ::Admin::HardpointPolicy

            v2_query_params["sorts"] = "sc_name asc"

            @q = authorized_scope(Hardpoint.where(parent_type: "Model").includes(:component, hardpoints: :component)).ransack(v2_query_params)

            @hardpoints = @q.result
              .page(params.fetch(:page, nil))
              .per(params.fetch(:per_page, nil))

            render "admin/api/v1/hardpoints/index"
          else
            authorize! with: ::Admin::ModelHardpointPolicy

            legacy_query_params["sorts"] = "name asc"

            @q = authorized_scope(ModelHardpoint.includes(:component, model_hardpoint_loadouts: :component)).ransack(legacy_query_params)

            @model_hardpoints = @q.result
              .page(params.fetch(:page, nil))
              .per(params.fetch(:per_page, nil))
          end
        end

        def create
          if hardpoints_v2?
            @hardpoint = Hardpoint.new(v2_hardpoint_params)

            authorize! @hardpoint, with: ::Admin::HardpointPolicy

            if @hardpoint.save
              render "admin/api/v1/hardpoints/show", status: :created
            else
              render json: ValidationError.new("hardpoint.create", errors: @hardpoint.errors), status: :bad_request
            end
          else
            @model_hardpoint = ModelHardpoint.new(legacy_hardpoint_params)

            authorize! @model_hardpoint, with: ::Admin::ModelHardpointPolicy

            if @model_hardpoint.save
              render :show, status: :created
            else
              render json: ValidationError.new("model_hardpoint.create", errors: @model_hardpoint.errors), status: :bad_request
            end
          end
        end

        def show
          render "admin/api/v1/hardpoints/show" if hardpoints_v2?
        end

        def update
          if hardpoints_v2?
            if @hardpoint.update(v2_hardpoint_params)
              render "admin/api/v1/hardpoints/show", status: :ok
            else
              render json: ValidationError.new("hardpoint.update", errors: @hardpoint.errors), status: :bad_request
            end
          elsif @model_hardpoint.update(legacy_hardpoint_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("model_hardpoint.update", errors: @model_hardpoint.errors), status: :bad_request
          end
        end

        def destroy
          if hardpoints_v2?
            @hardpoint.destroy
          else
            @model_hardpoint.destroy
          end

          head :no_content
        end

        private def hardpoints_v2?
          feature_enabled?("hardpoints-v2")
        end

        private def set_hardpoint
          if hardpoints_v2?
            @hardpoint = Hardpoint.find(params[:id])
            authorize! @hardpoint, with: ::Admin::HardpointPolicy
          else
            @model_hardpoint = ModelHardpoint.find(params[:id])
            authorize! @model_hardpoint, with: ::Admin::ModelHardpointPolicy
          end
        end

        private def legacy_hardpoint_params
          @legacy_hardpoint_params ||= params.permit(
            :name, :source, :key, :hardpoint_type, :group, :category, :sub_category,
            :size, :details, :mount, :item_slots, :loadout_identifier,
            :component_id, :model_id
          )
        end

        private def v2_hardpoint_params
          @v2_hardpoint_params ||= params.permit(
            :sc_name, :name, :source, :group, :category, :details,
            :min_size, :max_size, :types, :group_key, :matrix_key,
            :component_id, :model_id, :parent_id
          ).tap do |p|
            # Map name to sc_name for compatibility with frontend
            p[:sc_name] = p.delete(:name) if p[:name].present? && p[:sc_name].blank?

            # Map model_id to parent_id/parent_type for compatibility with frontend
            if p[:model_id].present? && p[:parent_id].blank?
              p[:parent_id] = p.delete(:model_id)
              p[:parent_type] = "Model"
            else
              p.delete(:model_id)
              p[:parent_type] = "Model" if p[:parent_id].present?
            end
          end
        end

        private def legacy_query_params
          @legacy_query_params ||= begin
            q = params.permit(q: [
              :model_id_eq, :group_eq, :hardpoint_type_eq, :source_eq, :name_cont, :sorts
            ]).fetch(:q, {})

            if q[:source_eq].present?
              q[:source_eq] = ModelHardpoint.sources[q[:source_eq]]
            end

            q
          end
        end

        private def v2_query_params
          @v2_query_params ||= begin
            q = params.permit(q: [
              :model_id_eq, :parent_id_eq, :group_eq, :category_eq, :source_eq, :sc_name_cont, :sorts
            ]).fetch(:q, {})

            # Map model_id_eq to parent_id_eq for compatibility with frontend
            if q[:model_id_eq].present? && q[:parent_id_eq].blank?
              q[:parent_id_eq] = q.delete(:model_id_eq)
            else
              q.delete(:model_id_eq)
            end

            if q[:source_eq].present?
              q[:source_eq] = Hardpoint.sources[q[:source_eq]]
            end

            q
          end
        end
      end
    end
  end
end
