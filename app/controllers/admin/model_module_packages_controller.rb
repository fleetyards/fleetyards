# frozen_string_literal: true

module Admin
  class ModelModulePackagesController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_model_module_packages
      @q = ModelModulePackage.ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @model_module_packages = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_model_module_packages
      @model_module_package = ModelModulePackage.new
    end

    def create
      authorize! :create, :admin_model_module_packages
      @model_module_package = ModelModulePackage.new(model_module_package_params)
      if model_module_package.save
        redirect_to admin_model_module_packages_path(params: index_back_params, anchor: model_module_package.id), notice: I18n.t(:'messages.create.success', resource: I18n.t(:'resources.model_module_package'))
      else
        render 'new', error: I18n.t(:'messages.create.failure', resource: I18n.t(:'resources.model_module_package'))
      end
    end

    def edit
      authorize! :update, model_module_package
    end

    def update
      authorize! :update, model_module_package
      if model_module_package.update(model_module_package_params)
        redirect_to admin_model_module_packages_path(params: index_back_params, anchor: model_module_package.id), notice: I18n.t(:'messages.update.success', resource: I18n.t(:'resources.model_module_package'))
      else
        render 'edit', error: I18n.t(:'messages.update.failure', resource: I18n.t(:'resources.model_module_package'))
      end
    end

    def destroy
      authorize! :destroy, model_module_package
      if model_module_package.destroy
        redirect_to admin_model_module_packages_path(params: index_back_params, anchor: model_module_package.id), notice: I18n.t(:'messages.destroy.success', resource: I18n.t(:'resources.model_module_package'))
      else
        redirect_to admin_model_module_packages_path(params: index_back_params, anchor: model_module_package.id), error: I18n.t(:'messages..destroy.failure', resource: I18n.t(:'resources.model_module_package'))
      end
    end

    private def model_module_package_params
      @model_module_package_params ||= params.require(:model_module_package).permit(
        :name, :hidden, :active, :store_image, :store_image_cache, :remove_store_image, :model_id,
        :pledge_price, :description, :production_status, module_package_items_attributes: %i[
          id model_module_id _destroy
        ]
      )
    end

    private def save_filters
      session[:model_module_packages_filters] = query_params(
        :name_or_slug_cont
      ).to_h
      session[:model_module_packages_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:model_module_packages_filters],
        page: session[:model_module_packages_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def model_module_package
      @model_module_package ||= ModelModulePackage.where(id: params.fetch(:id, nil)).first
    end
    helper_method :model_module_package

    private def set_active_nav
      @active_nav = 'admin-model_module_packages'
    end
  end
end
