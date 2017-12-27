# frozen_string_literal: true

module Admin
  class TradeHubsController < BaseController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_trade_hubs
      @q = TradeHub.ransack(params[:q])
      @trade_hubs = @q.result
                      .page(params.fetch(:page) { nil })
                      .per(40)
    end

    def new
      authorize! :create, :admin_trade_hubs
      @trade_hub = TradeHub.new
    end

    def create
      authorize! :create, :admin_trade_hubs
      @trade_hub = TradeHub.new(trade_hub_params)
      if trade_hub.save
        redirect_to admin_trade_hubs_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.trade_hub"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.trade_hub"))
      end
    end

    def edit
      authorize! :update, trade_hub
    end

    def update
      authorize! :update, trade_hub
      if trade_hub.update(trade_hub_params)
        redirect_to admin_trade_hubs_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.trade_hub"))
      else
        render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.trade_hub"))
      end
    end

    def destroy
      authorize! :destroy, trade_hub
      if trade_hub.destroy
        redirect_to admin_trade_hubs_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.trade_hub"))
      else
        redirect_to admin_trade_hubs_path, error: I18n.t(:"messages.destroy.failure", resource: I18n.t(:"resources.trade_hub"))
      end
    end

    private def save_filters
      session[:trade_hubs_filters] = params[:q]
      session[:trade_hubs_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:trade_hubs_filters],
        page: session[:trade_hubs_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def trade_hub_params
      @trade_hub_params ||= params.require(:trade_hub).permit(
        :name, :planet, :system, :station_type,
        trade_commodities_attributes: %i[
          id commodity_id sell_price buy_price buy sell _destroy
        ]
      )
    end

    private def trade_hub
      @trade_hub ||= TradeHub.where(id: params.fetch(:id, nil)).first
    end
    helper_method :trade_hub

    private def set_active_nav
      @active_nav = 'admin-trade-hubs'
    end
  end
end
