# frozen_string_literal: true

module Admin
  class ModelUpgradesController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_model_upgrades
      @q = ModelUpgrade.ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @model_upgrades = @q.result
                          .page(params.fetch(:page) { nil })
                          .per(40)
    end

    def new
      authorize! :create, :admin_model_upgrades
      @model_upgrade = ModelUpgrade.new
    end

    def create
      authorize! :create, :admin_model_upgrades
      @model_upgrade = ModelUpgrade.new(model_upgrade_params)
      if model_upgrade.save
        redirect_to admin_model_upgrades_path(params: index_back_params, anchor: model_upgrade.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.model_upgrade"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.model_upgrade"))
      end
    end

    def edit
      authorize! :update, model_upgrade
    end

    def update
      authorize! :update, model_upgrade
      if model_upgrade.update(model_upgrade_params)
        redirect_to admin_model_upgrades_path(params: index_back_params, anchor: model_upgrade.id), notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.model_upgrade"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.model_upgrade"))
      end
    end

    def destroy
      authorize! :destroy, model_upgrade
      if model_upgrade.destroy
        redirect_to admin_model_upgrades_path(params: index_back_params, anchor: model_upgrade.id), notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.model_upgrade"))
      else
        redirect_to admin_model_upgrades_path(params: index_back_params, anchor: model_upgrade.id), error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.model_upgrade"))
      end
    end

    private def model_upgrade_params
      @model_upgrade_params ||= params.require(:model_upgrade).permit(
        :name, :hidden, :active, :store_image, :store_image_cache, :remove_store_image,
        :pledge_price, :description, upgrade_kits_attributes: %i[
          id model_id _destroy
        ]
      )
    end

    private def save_filters
      session[:model_upgrades_filters] = params[:q]
      session[:model_upgrades_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:model_upgrades_filters],
        page: session[:model_upgrades_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def model_upgrade
      @model_upgrade ||= ModelUpgrade.where(id: params.fetch(:id, nil)).first
    end
    helper_method :model_upgrade

    private def set_active_nav
      @active_nav = 'admin-model_upgrades'
    end
  end
end
