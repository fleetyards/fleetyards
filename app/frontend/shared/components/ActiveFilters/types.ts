export interface ActiveFilter {
  id: string;
  label: string;
  remove: () => void | Promise<void>;
}
