// Docs app route locations

import type { SimpleRoute } from "@/types/route-helpers";

export type DocsRouteLocation = SimpleRoute<
  "home" | "api" | "api-v1" | "embed" | "media"
>;

export type DocsRouteName = DocsRouteLocation["name"];
