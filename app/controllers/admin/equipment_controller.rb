# frozen_string_literal: true

module Admin
  class EquipmentController < BaseController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_equipment
      @q = Equipment.order(name: :asc)
                    .ransack(params[:q])
      @equipment_list = @q.result
                          .page(params.fetch(:page) { nil })
                          .per(40)
    end

    def new
      authorize! :create, :admin_equipment
      @equipment = Equipment.new
    end

    def create
      authorize! :create, :admin_equipment
      @equipment = Equipment.new(equipment_params)
      if equipment.save
        redirect_to admin_equipment_index_path(params: index_back_params, anchor: equipment.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.equipment"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.equipment"))
      end
    end

    def edit
      authorize! :update, equipment
    end

    def update
      authorize! :update, equipment
      if equipment.update(equipment_params)
        redirect_to admin_equipment_index_path(params: index_back_params, anchor: equipment.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.equipment"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.equipment"))
      end
    end

    def destroy
      authorize! :destroy, equipment
      if equipment.destroy
        redirect_to admin_equipment_index_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.equipment"))
      else
        redirect_to admin_equipment_index_path, error: I18n.t(:"messages.destroy.failure", resource: I18n.t(:"resources.equipment"))
      end
    end

    private def save_filters
      session[:equipment_filters] = params[:q]
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
        :name, :description, :equipment_type, :item_type, :weapon_class, :size, :grade, :range, :extras,
        :weapon_class, :damage_reduction, :rate_of_fire, :hidden, :store_image, :store_image_cache,
        :remove_store_image, :manufacturer_id, :slot
      )
    end

    private def equipment
      @equipment ||= Equipment.where(id: params.fetch(:id, nil)).first
    end
    helper_method :equipment

    private def set_active_nav
      @active_nav = 'admin-equipment'
    end
  end
end
