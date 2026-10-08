# `slug` rather than the id: it is unique as of the catalogue work, and the
# public pages are built on it. `weapons` is a collection route, which Rails
# draws ahead of `:slug`, so it keeps answering rather than resolving as a
# component named "weapons".
resources :components, only: %i[index show], param: :slug do
  get :weapons, on: :collection

  # A member route rather than part of the detail payload: builds are pruned and
  # the change log is not, so this answers from a different table and would only
  # make `show` heavier for the readers who never open the tab.
  get :changes, on: :member
end

namespace :filters do
  resources :components, only: [] do
    get :categories, on: :collection
    get "sub-types", to: "components#sub_types", on: :collection
  end
end
