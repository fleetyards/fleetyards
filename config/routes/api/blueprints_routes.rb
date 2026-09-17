# `slug` rather than the id: it comes from the record key, so it is stable and
# unique even where two recipes make the same thing -- which three outputs in
# the current build do.
resources :blueprints, only: %i[index show], param: :slug
