resources :vehicles, only: [] do
  resources :loadouts, controller: "vehicle_loadouts", only: %i[index show create update destroy] do
    member do
      put :activate
    end
  end
end
