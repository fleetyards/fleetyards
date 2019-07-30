# frozen_string_literal: true

module Admin
  class ComponentsController < BaseController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_components
      @q = Component.ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @components = @q.result
                      .page(params.fetch(:page) { nil })
                      .per(40)
    end

    def new
      authorize! :create, :admin_components
      @component = Component.new
    end

    def create
      authorize! :create, :admin_components
      @component = Component.new(component_params)
      if component.save
        redirect_to admin_components_path(params: index_back_params, anchor: component.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.component"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.component"))
      end
    end

    def edit
      authorize! :update, component
    end

    def update
      authorize! :update, component
      if component.update(component_params)
        redirect_to admin_components_path(params: index_back_params, anchor: component.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.component"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.component"))
      end
    end

    def destroy
      authorize! :destroy, component
      if component.destroy
        redirect_to admin_components_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.component"))
      else
        redirect_to admin_components_path, error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.component"))
      end
    end

    def toggle
      authorize! :toggle, component

      respond_to do |format|
        format.js do
          if component.update(component_params)
            message = I18n.t(:"messages.disabled.success", resource: I18n.t(:"resources.component"))
            message = I18n.t(:"messages.enabled.success", resource: I18n.t(:"resources.component")) if component.enabled?
            render json: { message: message }
          else
            render json: false, status: :bad_request
          end
        end
        format.html do
          redirect_to admin_components_path
        end
      end
    end

    private def save_filters
      session[:components_filters] = params[:q]
      session[:components_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:components_filters],
        page: session[:components_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def component_params
      @component_params ||= params.require(:component).permit(
        :name, :manufacturer_id, :description, :item_type, :item_class, :store_image,
        :store_image_cache, :remove_store_image, :component_class, :size, :grade
      )
    end

    private def component
      @component ||= Component.where(id: params.fetch(:id, nil)).first
    end
    helper_method :component

    private def set_active_nav
      @active_nav = 'admin-components'
    end
  end
end
