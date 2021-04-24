# frozen_string_literal: true

class PricesJob < ApplicationJob
  def perform
    ShopCommodity.find_each(&:update_prices)
  end
end
