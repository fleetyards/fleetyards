resources :components, only: [:index] do
  get :class_filters, to: "filters/components#classes", on: :collection # DEPRECATED
  get :item_type_filters, to: "filters/components#item_types", on: :collection # DEPRECATED
end

namespace :filters do
  resources :components, only: [] do
    get :classes, on: :collection
    get "item-types", to: "components#item_types", on: :collection
  end
end
