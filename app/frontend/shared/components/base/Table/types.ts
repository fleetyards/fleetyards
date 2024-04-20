export type BaseTableColumn = {
  name: string;
  label: string;
  field?: string;
  class?: string;
  flexGrow?: number;
  width?: string;
  minWidth?: string;
  mobile?: boolean;
  centered?: boolean;
  sortable?: boolean;
};
