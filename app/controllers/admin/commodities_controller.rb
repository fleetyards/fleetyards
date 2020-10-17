# frozen_string_literal: true

module Admin
  class CommoditiesController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_commodities
      @q = Commodity.ransack(params[:q])

      @q.sorts = 'name asc' if @q.sorts.empty?

      @commodities = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_commodities
      @commodity = Commodity.new
    end

    def create
      authorize! :create, :admin_commodities
      @commodity = Commodity.new(commodity_params)
      if commodity.save
        redirect_to admin_commodities_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.commodity"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.commodity"))
      end
    end

    def edit
      authorize! :update, commodity
    end

    def update
      authorize! :update, commodity
      if commodity.update(commodity_params)
        redirect_to admin_commodities_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.commodity"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.commodity"))
      end
    end

    def destroy
      authorize! :destroy, commodity
      if commodity.destroy
        redirect_to admin_commodities_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.commodity"))
      else
        redirect_to admin_commodities_path, error: I18n.t(:"messages.destroy.failure", resource: I18n.t(:"resources.commodity"))
      end
    end

    private def save_filters
      session[:commodities_filters] = params[:q]
      session[:commodities_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:commodities_filters],
        page: session[:commodities_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def commodity_params
      @commodity_params ||= params.require(:commodity).permit(
        :name, :store_image, :commodity_type, :store_image_cache, :remove_store_image
      )
    end

    private def commodity
      @commodity ||= Commodity.where(id: params.fetch(:id, nil)).first
    end
    helper_method :commodity

    private def set_active_nav
      @active_nav = 'admin-commodities'
    end
  end
end
