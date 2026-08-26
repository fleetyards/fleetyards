# frozen_string_literal: true

module Admin
  module Api
    module V1
      class EquipmentController < ::Admin::Api::BaseController
        before_action :set_equipment, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::EquipmentPolicy

          sorts = sorting_params(Equipment, equipment_query_params[:sorts])
          name_sort = sorts.find { |sort| sort.start_with?("name ") }
          equipment_query_params["sorts"] = sorts - [name_sort].compact

          @q = authorized_scope(Equipment.all).includes(:manufacturer, :item_prices).ransack(equipment_query_params)

          result = @q.result

          # `ransack_alias :name` points name at name_or_slug so a search matches
          # either, which leaves ransack unable to sort by it -- it drops the
          # term without erroring. Name ordering is applied here instead, which
          # also covers DEFAULT_SORTING_PARAMS.
          result = result.order(name: name_sort.split.last.to_sym) if name_sort

          @equipment = result
            .page(params[:page])
            .per(per_page(Equipment))
        end

        def show
        end

        def create
          @equipment = Equipment.new(equipment_params)

          authorize! @equipment, with: ::Admin::EquipmentPolicy

          return if @equipment.save

          render json: ValidationError.new("equipment.create", errors: @equipment.errors), status: :bad_request
        end

        def update
          return if @equipment.update_with_facts(equipment_params)

          render json: ValidationError.new("equipment.update", errors: @equipment.errors), status: :bad_request
        end

        def destroy
          return if @equipment.destroy

          render json: ValidationError.new("equipment.destroy", errors: @equipment.errors), status: :bad_request
        end

        # All four are declared in the schema and reached by a generated client,
        # so they answer 401/403 like the rest of the resource rather than
        # handing the type lists to any signed-in admin.
        def type_filters
          authorize! with: ::Admin::EquipmentPolicy

          @filters = Equipment.type_filters

          render "api/shared/filters"
        end

        def slot_filters
          authorize! with: ::Admin::EquipmentPolicy

          @filters = Equipment.slot_filters

          render "api/shared/filters"
        end

        def item_type_filters
          authorize! with: ::Admin::EquipmentPolicy

          @filters = Equipment.item_type_filters

          render "api/shared/filters"
        end

        def weapon_class_filters
          authorize! with: ::Admin::EquipmentPolicy

          @filters = Equipment.weapon_class_filters

          render "api/shared/filters"
        end

        private def set_equipment
          @equipment = Equipment.find(params[:id])

          authorize! @equipment, with: ::Admin::EquipmentPolicy
        end

        private def equipment_params
          @equipment_params ||= params.permit(
            :name, :description, :equipment_type, :item_type, :sub_type, :weapon_class,
            :slot, :size, :grade, :rate_of_fire, :range, :storage, :volume,
            :damage_reduction, :temperature_rating, :radiation_protection,
            :radiation_scrub_rate, :g_force_tolerance, :core_compatibility,
            :backpack_compatibility, :manufacturer_id, :hidden, :store_image,
            :sc_key, :sc_ref
          )
        end

        private def equipment_query_params
          @equipment_query_params ||= params.permit(q: [
            :name_cont, :name_eq, :id_eq, :equipment_type_eq, :equipment_type_cont,
            :item_type_eq, :item_type_cont, :sub_type_cont, :weapon_class_cont,
            :hidden_eq, :store_image_blank, :buy_price_gteq, :buy_price_lteq, :sell_price_gteq,
            :sell_price_lteq, :sorts,
            sorts: [], name_in: [], id_in: [], equipment_type_in: [], item_type_in: [],
            weapon_class_in: [], slot_in: [], manufacturer_id_in: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
