resources :character_bodies, path: "character-bodies", only: %i[index]
resources :outfits, only: %i[index show create update destroy]
resources :character_faces, path: "character-faces", only: %i[index create update destroy]
get "character-faces/shared/:token" => "shared_character_faces#show", :as => :shared_character_face
resources :armor_sets, path: "armor-sets", only: %i[index]
