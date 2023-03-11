import type { Route } from "vue-router";

export type TBreadCrumb = {
  label: string;
  to: Partial<Route>;
};
