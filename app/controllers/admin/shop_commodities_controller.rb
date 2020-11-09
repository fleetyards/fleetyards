# frozen_string_literal: true

module Admin
  class ShopCommoditiesController < ::Admin::ApplicationController
    before_action :set_active_nav

    def index
      authorize! :index, :shop_commodities
      @app_enabled = true
    end

    def confirmation
      @active_nav = 'admin-shop_commodities-confirmation'
      authorize! :index, :shop_commodities
      @app_enabled = true
    end

    private def set_active_nav
      @active_nav = 'admin-shop_commodities'
    end

    private def shop
      @shop ||= Shop.find(params[:shop_id])
    end
    helper_method :shop

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:shops_filters],
        page: session[:shops_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params
  end
end
