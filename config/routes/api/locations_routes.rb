# By slug: it is made from the name, and the parent's name where another place
# shares it, so it reads as the place -- /locations/outpost-54-aberdeen.
resources :locations, only: %i[index show], param: :slug do
  collection do
    # Every jump point in the listed systems and the system it leads to: what
    # the systems page joins the systems with.
    get "jump-points", to: "locations#jump_points"
  end

  member do
    # The system the place is in, as its bodies: what the strip at the top of
    # every location page draws.
    get :tree
    # What sits directly inside, by kind, namesakes folded together.
    get :contents
    # The shops UEX lists at the place, with what each sells.
    get :shops
    # Who of the reader's friends and fleet mates is there, or inside it.
    get :people
  end
end
