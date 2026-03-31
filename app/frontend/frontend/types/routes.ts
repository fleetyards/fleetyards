// Frontend app route locations

import type {
  SimpleRoute,
  ParamRoute,
  SlugParams,
  TokenParams,
  UsernameParams,
  IdParams,
} from "@/types/route-helpers";

type FrontendSimpleRoutes =
  | "home"
  | "impressum"
  | "privacy-policy"
  | "compare"
  | "stats"
  | "fleets"
  | "images"
  | "settings"
  | "signup"
  | "signup-auth-callback"
  | "login"
  | "oauth-authorize"
  | "request-password"
  | "404"
  // Ships
  | "ships"
  | "ships-viewer"
  | "ships-fleetchart"
  // Hangar
  | "hangar"
  | "hangar-wishlist"
  | "hangar-preview"
  | "hangar-fleetchart"
  | "hangar-stats"
  // Fleets
  | "fleet-add"
  | "fleet-preview"
  | "fleet-invites"
  // Settings
  | "settings-profile"
  | "settings-account"
  | "settings-notifications"
  | "settings-hangar"
  | "settings-features"
  | "settings-security"
  | "settings-two-factor-enable"
  | "settings-two-factor-disable"
  | "settings-two-factor-backup-codes"
  | "settings-oauth-applications"
  | "settings-oauth-application-create"
  // Tools
  | "tools"
  | "travel-times"
  | "cargo-grids"
  // Visual Tests (dev only)
  | "visual-tests"
  | "visual-tests-panels"
  | "visual-tests-buttons"
  | "visual-tests-tables";

export type FrontendRouteLocation =
  | SimpleRoute<FrontendSimpleRoutes>
  // Ships (slug)
  | ParamRoute<"ship", SlugParams>
  | ParamRoute<"ship-images", SlugParams>
  | ParamRoute<"ship-videos", SlugParams>
  | ParamRoute<"ship-viewer", SlugParams>
  // Hangar (username)
  | ParamRoute<"hangar-public", UsernameParams>
  | ParamRoute<"hangar-public-fleetchart", UsernameParams>
  | ParamRoute<"wishlist-public", UsernameParams>
  // Fleets (slug)
  | ParamRoute<"fleet", SlugParams>
  | ParamRoute<"fleet-ships", SlugParams>
  | ParamRoute<"fleet-fleetchart", SlugParams>
  | ParamRoute<"fleet-members", SlugParams>
  | ParamRoute<"fleet-members-index", SlugParams>
  | ParamRoute<"fleet-members-invites", SlugParams>
  | ParamRoute<"fleet-settings", SlugParams>
  | ParamRoute<"fleet-settings-membership", SlugParams>
  | ParamRoute<"fleet-settings-fleet", SlugParams>
  | ParamRoute<"fleet-settings-roles", SlugParams>
  | ParamRoute<"fleet-stats", SlugParams>
  // Fleets (token)
  | ParamRoute<"fleet-invite", TokenParams>
  // Auth (token)
  | ParamRoute<"change-password", TokenParams>
  | ParamRoute<"confirm", TokenParams>
  // Settings (id)
  | ParamRoute<"settings-oauth-application", IdParams>
  | ParamRoute<"settings-oauth-application-edit", IdParams>;

export type FrontendRouteName = FrontendRouteLocation["name"];
