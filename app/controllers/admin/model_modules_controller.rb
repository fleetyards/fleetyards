# frozen_string_literal: true

module Admin
  class ModelModulesController < BaseController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_model_modules
      @q = ModelModule.ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @model_modules = @q.result
                         .page(params.fetch(:page) { nil })
                         .per(40)
    end

    def new
      authorize! :create, :admin_model_modules
      @model_module = ModelModule.new
    end

    def create
      authorize! :create, :admin_model_modules
      @model_module = ModelModule.new(model_module_params)
      if model_module.save
        redirect_to admin_model_modules_path(params: index_back_params, anchor: model_module.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.model_module"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.model_module"))
      end
    end

    def edit
      authorize! :update, model_module
    end

    def update
      authorize! :update, model_module
      if model_module.update(model_module_params)
        redirect_to admin_model_modules_path(params: index_back_params, anchor: model_module.id), notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.model_module"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.model_module"))
      end
    end

    def destroy
      authorize! :destroy, model_module
      if model_module.destroy
        redirect_to admin_model_modules_path(params: index_back_params, anchor: model_module.id), notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.model_module"))
      else
        redirect_to admin_model_modules_path(params: index_back_params, anchor: model_module.id), error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.model_module"))
      end
    end

    private def model_module_params
      @model_module_params ||= params.require(:model_module).permit(
        :name, :hidden, :active, :store_image, :store_image_cache, :remove_store_image,
        :pledge_price, :description, :production_status, module_hardpoints_attributes: %i[
          id model_id _destroy
        ]
      )
    end

    private def save_filters
      session[:model_modules_filters] = params[:q]
      session[:model_modules_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:model_modules_filters],
        page: session[:model_modules_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def model_module
      @model_module ||= ModelModule.where(id: params.fetch(:id, nil)).first
    end
    helper_method :model_module

    private def set_active_nav
      @active_nav = 'admin-model_modules'
    end
  end
end
