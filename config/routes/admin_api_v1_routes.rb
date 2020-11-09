# frozen_string_literal: true

v1_admin_api_routes = lambda do
  resources :models, only: %i[index] do
    get :options, on: :collection
    get :images, on: :member
  end

  resources :stations, only: %i[index] do
    get :options, on: :collection
    get :images, on: :member
  end

  resource :equipment, only: [] do
    get :weapons, on: :collection
    get :attachments, on: :collection
    get :utilities, on: :collection
  end

  resources :equipment, only: [:index]
  resources :commodities, only: [:index]
  resources :components, only: [:index]
  resources :model_modules, path: 'model-modules', only: [:index]
  resources :model_paints, path: 'model-paints', only: [:index]

  resource :stats, only: [] do
    get 'quick-stats' => 'stats#quick_stats'
    get 'most-viewed-pages' => 'stats#most_viewed_pages'
    get 'visits-per-day' => 'stats#visits_per_day'
    get 'visits-per-month' => 'stats#visits_per_month'
    get 'registrations-per-month' => 'stats#registrations_per_month'
  end

  resources :images, only: %i[index create destroy update]

  resources :shops, only: [] do
    resources :shop_commodities, path: 'commodities', only: %i[create index destroy update] do
      member do
        get 'buy-prices' => 'shop_commodities#buy_prices'
        get 'sell-prices' => 'shop_commodities#sell_prices'
        get 'rental-prices' => 'shop_commodities#rental_prices'
      end
    end
  end

  resources :shop_commodities, path: 'shop-commodities', only: %i[index destroy] do
    member do
      put :confirm
    end
  end

  resources :commodity_prices, path: 'commodity-prices', only: [:index, :destroy] do
    collection do
      post 'create-sell-price' => 'commodity_prices#create_sell_price'
      post 'create-buy-price' => 'commodity_prices#create_buy_price'
      post 'create-rental-price' => 'commodity_prices#create_rental_price'
      get 'time-ranges' => 'commodity_prices#time_ranges'
    end

    member do
      put :confirm
    end
  end
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_admin_api_routes
end
