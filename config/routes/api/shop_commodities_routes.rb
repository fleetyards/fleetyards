resources :shop_commodities, path: "shop-commodities", only: %i[index] do
  # DEPRECATED
  get "commodity-type-options", to: "/filters/shop_commodities#commodity_item_types", on: :collection
  get "sub-categories", to: "/filters/shop_commodities#sub_categories", on: :collection
end

namespace :filters do
  resources :shop_commodities, path: "shop-commodities", only: [] do
    get "commodity-type-options", to: "shop_commodities#commodity_item_types", on: :collection
    get "sub-categories", to: "shop_commodities#sub_categories", on: :collection
  end
end
