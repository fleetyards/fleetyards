export type BaseTableItem = Record<string, unknown>;

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
  sortable?: boolean;
  width?: string | number;
  align?: `${BaseTableColAlignmentEnum}`;
  class?: string;
  style?: string;
  attributeKey?: keyof T;
  attributeFn?: (record: T) => string;
};
