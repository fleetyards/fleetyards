# frozen_string_literal: true

class TradeRoutesWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['TRADE_ROUTES_QUEUE'] || 'fleetyards_trade_route_calculator').to_sym

  def perform
    ids = []

    ShopCommodity.commodity.visible.where.not(sell_price: nil).find_each do |origin|
      ShopCommodity.commodity.visible.where(commodity_item_id: origin.commodity_item_id).where.not(buy_price: nil).find_each do |destination|
        next unless (destination.buy_price - origin.sell_price).positive?

        trade_route = TradeRoute.find_or_create_by(
          origin_id: origin.id,
          destination_id: destination.id
        )

        ids << trade_route.id if trade_route.present?
      end
    end

    TradeRoute.where.not(id: ids).destroy_all
  end
end
