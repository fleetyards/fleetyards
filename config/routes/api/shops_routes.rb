# frozen_string_literal: true

# By slug: the shop and its place -- /shops/casaba-outlet-everus-harbor.
resources :shops, only: %i[show], param: :slug do
  # Everything it sells, one paginated list across the catalogues.
  get :items, on: :member
end
