# frozen_string_literal: true

resource :stats, only: [:show] do
  get :models_per_month, path: "models-per-month"
  get :models_by_size, path: "models-by-size"
  get :models_by_production_status, path: "models-by-production-status"
  get :models_by_manufacturer, path: "models-by-manufacturer"
  get :models_by_classification, path: "models-by-classification"
  get :components_by_class, path: "components-by-class"
end
