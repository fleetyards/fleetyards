# frozen_string_literal: true

require 'rsi/news_loader'

module Loaders
  class ScDataShopInventoriesJob < ::Loaders::BaseJob
    def perform
      ::ScData::ShopInventoryLoader.new.run
    end
  end
end
