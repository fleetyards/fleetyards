resources :equipment, only: %i[index show], param: :slug

namespace :filters do
  resources :equipment, only: [] do
    get :types, on: :collection
    get "item-types", to: "equipment#item_types", on: :collection
    get "sub-types", to: "equipment#sub_types", on: :collection
    get "weapon-classes", to: "equipment#weapon_classes", on: :collection
    get :slots, on: :collection
  end
end
