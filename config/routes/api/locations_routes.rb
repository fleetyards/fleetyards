# By slug: it is made from the name, and the parent's name where another place
# shares it, so it reads as the place -- /locations/outpost-54-aberdeen.
resources :locations, only: %i[index show], param: :slug
