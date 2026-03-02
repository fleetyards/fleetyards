import { type RouterLinkProps } from "vue-router";

export type ListMeta = {
  totalCount: number;
  perPage: number;
  currentPage: number;
  totalPages: number;
};

export type Crumb = {
  to: RouterLinkProps["to"];
  label?: string;
};
