# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ComponentsController < ::Admin::Api::BaseController
        skip_verify_authorized only: %i[class_filters item_type_filters]

        before_action :set_component, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::ComponentPolicy

          component_query_params["sorts"] = sorting_params(Component, component_query_params[:sorts])

          @q = authorized_scope(Component.all).includes(:manufacturer).ransack(component_query_params)

          @components = @q.result
            .page(params[:page])
            .per(per_page(Component))
        end

        def show
        end

        def create
          @component = Component.new(component_params)

          authorize! @component, with: ::Admin::ComponentPolicy

          return if @component.save

          render json: ValidationError.new("component.create", errors: @component.errors), status: :bad_request
        end

        def update
          return if @component.update(component_params)

          render json: ValidationError.new("component.update", errors: @component.errors), status: :bad_request
        end

        def destroy
          return if @component.destroy

          render json: ValidationError.new("component.destroy", errors: @component.errors), status: :bad_request
        end

        def class_filters
          @filters = Component.class_filters

          render "api/shared/filters"
        end

        def item_type_filters
          @filters = Component.item_type_filters

          render "api/shared/filters"
        end

        private def set_component
          @component = Component.find(params[:id])

          authorize! @component, with: ::Admin::ComponentPolicy
        end

        private def component_params
          @component_params ||= params.permit(
            :name, :component_class, :component_type, :component_sub_type,
            :size, :grade, :item_class, :item_type, :manufacturer_id,
            :description, :hidden, :store_image, :sc_key, :sc_ref
          )
        end

        private def component_query_params
          @component_query_params ||= params.permit(q: [
            :name_cont, :name_eq, :id_eq, :item_type_eq,
            :item_type_cont, :component_class_cont, :sorts,
            sorts: [], name_in: [], id_in: [], item_type_in: [], component_class_in: [],
            manufacturer_id_in: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
