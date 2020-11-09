# frozen_string_literal: true

module Admin
  class CommodityPricesController < ::Admin::ApplicationController
    def confirmation
      @active_nav = 'admin-commodity_prices-confirmation'
      authorize! :index, :commodity_prices
      @app_enabled = true
    end
  end
end
