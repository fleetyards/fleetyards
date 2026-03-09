export const AVAILABLE_SCOPES = [
  "public",
  "profile:read",
  "profile:write",
  "hangar",
  "hangar:read",
  "hangar:write",
  "fleet",
  "fleet:read",
  "fleet:write",
  "openid",
] as const;

export const DEFAULT_SCOPES = ["public", "profile:read"] as const;
