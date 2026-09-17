# `slug` rather than the id: it is unique as of the catalogue work, and the
# public pages are built on it. `weapons` is a collection route, which Rails
# draws ahead of `:slug`, so it keeps answering rather than resolving as a
# component named "weapons".
resources :components, only: %i[index show], param: :slug do
  get :weapons, on: :collection
end

# `classes` and `item-types` answer with a vocabulary no component in the
# current build carries -- `component_class` and `item_type` are empty on every
# row the game still ships, so a filter built on either matches nothing. Both
# are marked deprecated in the schema rather than removed: they are public, and
# a path that disappears without notice breaks whoever is calling it. The
# catalogue does not offer them.
namespace :filters do
  resources :components, only: [] do
    get :classes, on: :collection
    get "item-types", to: "components#item_types", on: :collection
    get :categories, on: :collection
    get "sub-types", to: "components#sub_types", on: :collection
  end
end
