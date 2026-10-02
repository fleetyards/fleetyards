# frozen_string_literal: true

# By slug: the shop and its place -- /shops/casaba-outlet-everus-harbor.
resources :shops, only: %i[show], param: :slug
