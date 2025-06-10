module Admin
  class ItemPricePolicy < BasePolicy
    private def resource_access
      [:item_prices]
    end
  end
end
