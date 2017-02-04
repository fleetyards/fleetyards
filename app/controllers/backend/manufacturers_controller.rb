# frozen_string_literal: true
module Backend
  class ManufacturersController < BaseController
    before_action :set_active_nav

    def index
      authorize! :index, :backend_manufacturers
      @manufacturers = Manufacturer.all
                                   .order(sort_column + " " + sort_direction)
                                   .page(params.fetch(:page) { nil })
                                   .per(20)
    end

    def new
      authorize! :create, :backend_manufacturers
      @manufacturer = Manufacturer.new
    end

    def create
      authorize! :create, :backend_manufacturers
      @manufacturer = Manufacturer.new(manufacturer_params)
      if manufacturer.save
        redirect_to backend_manufacturers_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.manufacturer"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.manufacturer"))
      end
    end

    def edit
      authorize! :update, manufacturer
    end

    def update
      authorize! :update, manufacturer
      if manufacturer.update(manufacturer_params)
        redirect_to backend_manufacturers_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.manufacturer"))
      else
        Rails.logger.debug manufacturer.errors.to_yaml
        render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.manufacturer"))
      end
    end

    def destroy
      authorize! :destroy, manufacturer
      if manufacturer.destroy
        redirect_to backend_manufacturers_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.manufacturer"))
      else
        redirect_to backend_manufacturers_path, error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.manufacturer"))
      end
    end

    def toggle
      authorize! :toggle, manufacturer

      respond_to do |format|
        format.js do
          if manufacturer.update(manufacturer_params)
            message = I18n.t(:"messages.disabled.success", resource: I18n.t(:"resources.manufacturer"))
            if manufacturer.enabled?
              message = I18n.t(:"messages.enabled.success", resource: I18n.t(:"resources.manufacturer"))
            end
            render json: { message: message }
          else
            render json: false, status: :bad_request
          end
        end
        format.html do
          redirect_to backend_manufacturers_path
        end
      end
    end

    private def manufacturer_params
      @manufacturer_params ||= params.require(:manufacturer).permit(:name, :enabled, :logo)
    end

    private def sort_column
      Manufacturer.column_names.include?(params[:sort]) ? params[:sort] : "id"
    end
    helper_method :sort_column

    private def manufacturer
      @manufacturer ||= Manufacturer.where(id: params.fetch(:id, nil)).first
    end
    helper_method :manufacturer

    private def set_active_nav
      @active_nav = 'backend-manufacturers'
    end
  end
end
