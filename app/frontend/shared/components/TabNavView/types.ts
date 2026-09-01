import { type RouterLinkProps } from "vue-router";

// A destination that is not a tab of this page. It leaves for a list somewhere
// else, so it never lights up as current and is set apart from the routed tabs
// above it.
export type TabNavLink = {
  to: RouterLinkProps["to"];
  label: string;
};
