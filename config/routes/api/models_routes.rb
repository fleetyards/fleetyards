resources :models, param: :slug, only: %i[index show] do
  collection do
    get :fleetchart
    get "with-docks" => "models#with_docks"
    get :unscheduled
    get :latest
    get :slugs
    get :updated
    get :filters
    get :classifications
    get "production-states" => "models#production_states"
    get :focus
    get :sizes
    get "cargo-options" => "models#cargo_options"
    get :embed
  end
  member do
    get :hardpoints
    get :images
    get :videos
    get :variants
    get :loaners
    get "snub-crafts" => "models#snub_crafts"
    get :modules
    get :module_packages, path: "module-packages"
    get :upgrades
    get :paints
    get :store_image, path: "store-image"
    get :fleetchart_image, path: "fleetchart-image"
  end
end

resources :model_paints, path: "model-paints", only: %i[index]
