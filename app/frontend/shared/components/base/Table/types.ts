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
  attributeKey?: keyof T | string;
  // The height of the media this column holds, which turns its placeholder
  // from a line into an image well of that height. Only needed where a cell
  // holds a thumbnail: a bar the height of a line stands in for neither its
  // shape nor its height.
  skeletonMedia?: string;
};
