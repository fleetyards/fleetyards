resources :hardpoints, only: [] do
  get :loadout_options, path: "loadout-options", on: :member
end
