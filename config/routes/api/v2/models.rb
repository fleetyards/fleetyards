# frozen_string_literal: true

resources :models, param: :slug, only: %i[index show] do
  collection do
    # get 'with-docks' => 'models#with_docks' # TODO: migrate to filter option on index route
    # get :unscheduled # TODO: migrate to filter option on index route
    # get :latest # TODO: migrate to sort option on index route
    # get 'cargo-options' => 'models#cargo_options' # TODO: migrate to sort option on index route
    get :embed
  end
  member do
    get :hardpoints
    get :images
    get :videos
    get :variants
    get :loaners
    get :modules
    get :module_packages, path: 'module-packages'
    get :upgrades
    get :paints
  end
end
