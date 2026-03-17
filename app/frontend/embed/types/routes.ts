// Embed app route locations

import type { SimpleRoute } from "@/types/route-helpers";

export type EmbedRouteLocation = SimpleRoute<"home">;

export type EmbedRouteName = EmbedRouteLocation["name"];
