# `slug` rather than the id: it comes from the record key, so it is stable and
# unique even where two recipes make the same thing -- which three outputs in
# the current build do.
resources :blueprints, only: %i[index show], param: :slug

# The materials a recipe can ask for, which is a small subset of the commodity
# catalogue -- 37 of 232 in the current build.
namespace :filters do
  resources :blueprints, only: [] do
    get :materials, on: :collection
  end
end
