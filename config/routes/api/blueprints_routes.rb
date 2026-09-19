# `slug` rather than the id: it comes from the record key, so it is stable and
# unique even where two recipes make the same thing -- which three outputs in
# the current build do.
resources :blueprints, only: %i[index show], param: :slug do
  # The personal marker, as a sub-resource rather than as a field on an update:
  # the catalogue row itself is not editable by anybody, and "I have this" is
  # the only thing a reader can say about it.
  member do
    put :own
    delete :own, action: :unown
  end
end

# The materials a recipe can ask for, which is a small subset of the commodity
# catalogue -- 37 of 232 in the current build.
namespace :filters do
  resources :blueprints, only: [] do
    get :materials, on: :collection
  end
end
