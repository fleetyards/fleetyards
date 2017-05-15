# frozen_string_literal: true

module Backend
  class ComponentsController < BaseController
    before_action :set_active_nav

    def index
      authorize! :index, :backend_components
      @components = Component.all
                             .order(sort_column + " " + sort_direction)
                             .page(params.fetch(:page) { nil })
                             .per(20)
    end

    def new
      authorize! :create, :backend_components
      @component = Component.new
    end

    def create
      authorize! :create, :backend_components
      @component = Component.new(component_params)
      if component.save
        redirect_to backend_components_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.component"))
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
        redirect_to backend_components_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.component"))
      else
        render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.component"))
      end
    end

    def destroy
      authorize! :destroy, component
      if component.destroy
        redirect_to backend_components_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.component"))
      else
        redirect_to backend_components_path, error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.component"))
      end
    end

    def toggle
      authorize! :toggle, component

      respond_to do |format|
        format.js do
          if component.update(component_params)
            message = I18n.t(:"messages.disabled.success", resource: I18n.t(:"resources.component"))
            if component.enabled?
              message = I18n.t(:"messages.enabled.success", resource: I18n.t(:"resources.component"))
            end
            render json: { message: message }
          else
            render json: false, status: :bad_request
          end
        end
        format.html do
          redirect_to backend_components_path
        end
      end
    end

    private def component_params
      @component_params ||= params.require(:component).permit(:name, :enabled)
    end

    private def sort_column
      Component.column_names.include?(params[:sort]) ? params[:sort] : "id"
    end
    helper_method :sort_column

    private def component
      @component ||= Component.where(id: params.fetch(:id, nil)).first
    end
    helper_method :component

    private def set_active_nav
      @active_nav = 'backend-components'
    end
  end
end
