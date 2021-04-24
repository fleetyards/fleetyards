# frozen_string_literal: true

class PricesJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: false

  def perform
    ShopCommodity.find_each(&:update_prices)
  end
end
