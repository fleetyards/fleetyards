# frozen_string_literal: true

admin_options = {
  path: (Rails.configuration.app.on_subdomain? ? "" : "admin"),
  constraints: ->(req) { !Rails.configuration.app.on_subdomain? || req.subdomain == "admin" }
}.compact

namespace :admin, **admin_options do
  draw "admin/api_routes"

  authenticate :admin_user, ->(u) { u.present? && u.has_access?(:workers) } do
    mount Sidekiq::Web => "/workers"
  end
  authenticate :admin_user, ->(u) { u.present? && u.has_access?(:pghero) } do
    mount PgHero::Engine => "/pghero"
  end
  authenticate :admin_user, ->(u) { u.present? && u.has_access?(:features) } do
    mount Flipper::UI.app(Flipper) => "/flipper", :as => :flipper
  end
  authenticate :admin_user, ->(u) { u.present? && u.has_access?(:maintenance) } do
    mount MaintenanceTasks::Engine, at: "/maintenance_tasks"
  end

  get "manifest-:digest", to: "base#manifest", as: :manifest

  root to: "base#index"
end

Rails.application.routes.append do
  namespace :admin, **admin_options do
    match "*path", to: "base#index", via: :all
  end
end
