// Shared route location helpers and param types

import type { LocationQueryRaw } from "vue-router";

// Route params
export interface SlugParams {
  slug: string;
}

export interface IdParams {
  id: string;
}

export interface TokenParams {
  token: string;
}

export interface UsernameParams {
  username: string;
}

export interface FeatureNameParams {
  name: string;
}

// Base route location shape
export interface RouteLocationBase {
  query?: LocationQueryRaw;
  hash?: string;
}

// Helper: route with no required params
export type SimpleRoute<N extends string> = RouteLocationBase & {
  name: N;
};

// Helper: route with required params
export type ParamRoute<N extends string, P> = RouteLocationBase & {
  name: N;
  params: P;
};

// Combined type for shared components that accept routes from any app
import type { FrontendRouteLocation } from "@/frontend/types/routes";
import type { AdminRouteLocation } from "@/admin/types/routes";
import type { DocsRouteLocation } from "@/docs/types/routes";
import type { EmbedRouteLocation } from "@/embed/types/routes";

export type RouteLocation =
  | FrontendRouteLocation
  | AdminRouteLocation
  | DocsRouteLocation
  | EmbedRouteLocation;

export type RouteName = RouteLocation["name"];
