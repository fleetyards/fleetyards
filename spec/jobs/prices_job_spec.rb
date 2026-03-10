# frozen_string_literal: true

require "rails_helper"

RSpec.describe PricesJob, :verify_partial_doubles do
  describe "#perform" do
    before do
      RSpec::Mocks.configuration.verify_partial_doubles = false
    end

    after do
      RSpec::Mocks.configuration.verify_partial_doubles = true
    end

    it "calls update_prices on each shop commodity" do
      shop_commodity = double("ShopCommodity", update_prices: true)
      allow(ShopCommodity).to receive(:find_each) { |&block| block.call(shop_commodity) }

      described_class.new.perform

      expect(shop_commodity).to have_received(:update_prices)
    end
  end
end
