// Admin app route locations

import type {
  SimpleRoute,
  ParamRoute,
  IdParams,
  FeatureNameParams,
} from "@/types/route-helpers";

type AdminSimpleRoutes =
  | "home"
  | "admin-images"
  | "admin-maintenance"
  | "admin-login"
  | "404"
  // Models
  | "admin-models"
  | "admin-model-create"
  // Model Paints
  | "admin-model-paints"
  | "admin-model-paint-create"
  // Model Modules
  | "admin-model-modules"
  | "admin-model-modules-packages"
  // Manufacturers
  | "admin-manufacturers"
  | "admin-manufacturer-create"
  // Components
  | "admin-components"
  | "admin-component-create"
  // Fleets
  | "admin-fleets"
  // Vehicles
  | "admin-vehicles"
  // Users
  | "admin-users"
  // Admins
  | "admin-admins"
  // OAuth Applications
  | "admin-oauth-applications"
  | "admin-oauth-application-create"
  // Maintenance
  | "pghero"
  | "admin-features"
  | "workers"
  | "tasks"
  | "rsi-api-status";

export type AdminRouteLocation =
  | SimpleRoute<AdminSimpleRoutes>
  // Models (id)
  | ParamRoute<"admin-model-edit", IdParams>
  | ParamRoute<"admin-model-edit-metrics", IdParams>
  | ParamRoute<"admin-model-edit-cargo-and-fuel", IdParams>
  | ParamRoute<"admin-model-edit-cargo-holds", IdParams>
  | ParamRoute<"admin-model-edit-prices", IdParams>
  | ParamRoute<"admin-model-edit-fleetchart", IdParams>
  | ParamRoute<"admin-model-edit-images", IdParams>
  | ParamRoute<"admin-model-edit-videos", IdParams>
  | ParamRoute<"admin-model-edit-positions", IdParams>
  | ParamRoute<"admin-model-edit-hardpoints", IdParams>
  | ParamRoute<"admin-model-edit-loaners", IdParams>
  | ParamRoute<"admin-model-edit-docks", IdParams>
  | ParamRoute<"admin-model-edit-paints", IdParams>
  | ParamRoute<"admin-model-edit-modules", IdParams>
  | ParamRoute<"admin-model-edit-upgrades", IdParams>
  | ParamRoute<"admin-model-edit-packages", IdParams>
  // Paints (id)
  | ParamRoute<"admin-model-paint-edit", IdParams>
  // Manufacturers (id)
  | ParamRoute<"admin-manufacturer-edit", IdParams>
  // Components (id)
  | ParamRoute<"admin-component-edit", IdParams>
  // Fleets (id)
  | ParamRoute<"admin-fleet-edit", IdParams>
  // Vehicles (id)
  | ParamRoute<"admin-vehicle-edit", IdParams>
  // Users (id)
  | ParamRoute<"admin-user-edit", IdParams>
  // Admins (id)
  | ParamRoute<"admin-admin-edit", IdParams>
  // OAuth (id)
  | ParamRoute<"admin-oauth-application-edit", IdParams>
  // Features (name)
  | ParamRoute<"admin-feature", FeatureNameParams>;

export type AdminRouteName = AdminRouteLocation["name"];
