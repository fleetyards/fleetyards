# frozen_string_literal: true

module Admin
  class ManufacturersController < BaseController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_manufacturers
      @q = Manufacturer.ransack(params[:q])
      @manufacturers = @q.result
                         .page(params.fetch(:page) { nil })
                         .per(40)
    end

    def new
      authorize! :create, :admin_manufacturers
      @manufacturer = Manufacturer.new
    end

    def create
      authorize! :create, :admin_manufacturers
      @manufacturer = Manufacturer.new(manufacturer_params)
      if manufacturer.save
        redirect_to admin_manufacturers_path(params: index_back_params, anchor: manufacturer.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.manufacturer"))
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
        redirect_to admin_manufacturers_path(params: index_back_params, anchor: manufacturer.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.manufacturer"))
      else
        Rails.logger.debug manufacturer.errors.to_yaml
        render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.manufacturer"))
      end
    end

    def destroy
      authorize! :destroy, manufacturer
      if manufacturer.destroy
        redirect_to admin_manufacturers_path(params: index_back_params, anchor: manufacturer.id), notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.manufacturer"))
      else
        redirect_to admin_manufacturers_path(params: index_back_params, anchor: manufacturer.id), error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.manufacturer"))
      end
    end

    private def save_filters
      session[:manufacturers_filters] = params[:q]
      session[:manufacturers_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:manufacturers_filters],
        page: session[:manufacturers_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def manufacturer_params
      @manufacturer_params ||= params.require(:manufacturer).permit(:name, :logo)
    end

    private def manufacturer
      @manufacturer ||= Manufacturer.where(id: params.fetch(:id, nil)).first
    end
    helper_method :manufacturer

    private def set_active_nav
      @active_nav = 'admin-manufacturers'
    end
  end
end
