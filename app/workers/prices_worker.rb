# frozen_string_literal: true

class PricesWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['PRICES_QUEUE'] || 'fleetyards_price_calculator').to_sym

  def perform
    ShopCommodity.find_each(&:update_prices)
  end
end
