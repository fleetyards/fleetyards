# frozen_string_literal: true

module Admin
  class EquipmentController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_equipment
      @q = Equipment.ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @equipment_list = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_equipment

      prefill = Equipment.find_by(id: params[:prefill_from]) if params[:prefill_from].present?
      prefill = prefill.attributes.slice!('created_at', 'updated_at', 'id', 'store_image') if prefill.present?

      @equipment = Equipment.new(prefill)
    end

    def create
      authorize! :create, :admin_equipment
      @equipment = Equipment.new(equipment_params)
      if equipment.save
        redirect_to admin_equipment_index_path(params: index_back_params, anchor: equipment.id), notice: I18n.t(:'messages.create.success', resource: I18n.t(:'resources.equipment'))
      else
        render 'new', error: I18n.t(:'messages.create.failure', resource: I18n.t(:'resources.equipment'))
      end
    end

    def edit
      authorize! :update, equipment
    end

    def update
      authorize! :update, equipment
      if equipment.update(equipment_params)
        redirect_to admin_equipment_index_path(params: index_back_params, anchor: equipment.id), notice: I18n.t(:'messages.create.success', resource: I18n.t(:'resources.equipment'))
      else
        render 'edit', error: I18n.t(:'messages.update.failure', resource: I18n.t(:'resources.equipment'))
      end
    end

    def destroy
      authorize! :destroy, equipment
      if equipment.destroy
        redirect_to admin_equipment_index_path, notice: I18n.t(:'messages.destroy.success', resource: I18n.t(:'resources.equipment'))
      else
        redirect_to admin_equipment_index_path, error: I18n.t(:'messages.destroy.failure', resource: I18n.t(:'resources.equipment'))
      end
    end

    private def save_filters
      session[:equipment_filters] = query_params(
        :name_or_slug_cont, :equipment_type_eq, :item_type_eq
      ).to_h
      session[:equipment_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:equipment_filters],
        page: session[:equipment_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def equipment_params
      @equipment_params ||= params.require(:equipment).permit(
        :name, :description, :equipment_type, :item_type, :weapon_class, :size, :grade, :range,
        :extras, :temperature_rating, :backpack_compatibility, :core_compatibility, :weapon_class,
        :damage_reduction, :rate_of_fire, :hidden, :store_image, :store_image_cache,
        :remove_store_image, :manufacturer_id, :slot, :storage, :volume
      )
    end

    private def equipment
      @equipment ||= Equipment.find(params[:id])
    end
    helper_method :equipment

    private def set_active_nav
      @active_nav = 'admin-equipment'
    end
  end
end
