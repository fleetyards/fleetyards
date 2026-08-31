# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ComponentsController < ::Admin::Api::BaseController
        before_action :set_component, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::ComponentPolicy

          normalize_sort_params(component_query_params)
          component_query_params["sorts"] = sorting_params(Component, component_query_params[:sorts])

          # The fallback join, not the fast one: the admin list has to show a
          # retired component, and one an admin created by hand that no load has
          # described yet.
          @q = authorized_scope(Component.with_facts(false))
            .includes(:manufacturer, :item_prices)
            .ransack(component_query_params)

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
          return if @component.update_with_facts(component_params)

          render json: ValidationError.new("component.update", errors: @component.errors), status: :bad_request
        end

        def destroy
          return if @component.destroy

          render json: ValidationError.new("component.destroy", errors: @component.errors), status: :bad_request
        end

        # Both are declared in the schema and reached by a generated client, so
        # they answer 401/403 like the rest of the resource rather than handing
        # the type lists to any signed-in admin.
        def class_filters
          authorize! with: ::Admin::ComponentPolicy

          @filters = Component.class_filters

          render "api/shared/filters"
        end

        def item_type_filters
          authorize! with: ::Admin::ComponentPolicy

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
            :item_type_cont, :component_class_cont, :store_image_blank, :buy_price_gteq,
            :buy_price_lteq, :sell_price_gteq, :sell_price_lteq, :s, :sorts,
            sorts: [], name_in: [], id_in: [], item_type_in: [], component_class_in: [],
            manufacturer_id_in: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
