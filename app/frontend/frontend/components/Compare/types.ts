export type CompareRow<T> = {
  key: string;
  value: (model: T) => string | number | undefined;
  height?: number;
  label?: string;
};
