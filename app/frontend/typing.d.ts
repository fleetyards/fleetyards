import "vue-router";

declare module "vue-router" {
  interface RouteMeta {
    title?: string;
    needsAuthentication?: boolean;
    quickSearch?: string;
    primaryAction?: boolean;
    backgroundImage?: string;
    icon?: string;
    exact?: boolean;
    activeRoute?: string;
    hide?: boolean;
  }
}
