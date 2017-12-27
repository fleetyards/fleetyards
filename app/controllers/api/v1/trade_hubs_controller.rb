# frozen_string_literal: true

module Api
  module V1
    class TradeHubsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      def index
        authorize! :index, :api_trade_hubs
        @q = TradeHub.ransack(query_params)

        @q.sorts = 'name asc' if @q.sorts.empty?

        @trade_hubs = @q.result.offset(params[:offset]).limit(params[:limit])
      end
    end
  end
end
