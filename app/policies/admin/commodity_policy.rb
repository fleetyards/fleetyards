module Admin
  class CommodityPolicy < BasePolicy
    private def resource_access
      [:commodities]
    end
  end
end
