resources :character_bodies, path: "character-bodies", only: %i[index]
resources :outfits, only: %i[index show create update destroy]
