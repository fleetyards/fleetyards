import { ModelSortEnum } from "@/services/fyAdminApi";

export enum BaseTableColAlignmentEnum {
  LEFT = "left",
  CENTER = "center",
  RIGHT = "right",
}

export enum BaseTableHeaderColVariantEnum {
  DEFAULT = "default",
  SELECTION = "selection",
  ACTIONS = "actions",
  EMPTY = "empty",
  LOADING = "loading",
}

export type BaseTableCol<T> = {
  name: string;
  label: string;
  class?: string;
  flexGrow?: number;
  width?: string;
  minWidth?: string;
  mobile?: boolean;
  alignment?: `${BaseTableColAlignmentEnum}`;
  sortable?: boolean;
  attributeKey?: keyof T;
};
