# frozen_string_literal: true

module Admin
  class ModelModulePackagesController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_model_module_packages
      @q = ModelModulePackage.ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @module_packages = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_model_module_packages
      @module_package = ModelModulePackage.new
    end

    def create
      authorize! :create, :admin_model_module_packages
      @module_package = ModelModulePackage.new(module_package_params)
      if module_package.save
        redirect_to admin_model_module_packages_path(params: index_back_params, anchor: module_package.id), notice: I18n.t(:'messages.create.success', resource: I18n.t(:'resources.model_module_package'))
      else
        render 'new', error: I18n.t(:'messages.create.failure', resource: I18n.t(:'resources.model_module_package'))
      end
    end

    def edit
      authorize! :update, module_package
    end

    def update
      authorize! :update, module_package
      if module_package.update(module_package_params)
        redirect_to admin_model_module_packages_path(params: index_back_params, anchor: module_package.id), notice: I18n.t(:'messages.update.success', resource: I18n.t(:'resources.model_module_package'))
      else
        render 'edit', error: I18n.t(:'messages.update.failure', resource: I18n.t(:'resources.model_module_package'))
      end
    end

    def destroy
      authorize! :destroy, module_package
      if module_package.destroy
        redirect_to admin_model_module_packages_path(params: index_back_params, anchor: module_package.id), notice: I18n.t(:'messages.destroy.success', resource: I18n.t(:'resources.model_module_package'))
      else
        redirect_to admin_model_module_packages_path(params: index_back_params, anchor: module_package.id), error: I18n.t(:'messages..destroy.failure', resource: I18n.t(:'resources.model_module_package'))
      end
    end

    private def module_package_params
      @module_package_params ||= params.require(:model_module_package).permit(
        :name, :hidden, :active, :store_image, :store_image_cache, :remove_store_image, :model_id,
        :angled_view, :angled_view_cache, :remove_angled_view, :top_view, :top_view_cache,
        :remove_top_view, :side_view, :side_view_cache, :remove_side_view,
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

    private def module_package
      @module_package ||= ModelModulePackage.where(id: params.fetch(:id, nil)).first
    end
    helper_method :module_package

    private def set_active_nav
      @active_nav = 'admin-model_module_packages'
    end
  end
end
