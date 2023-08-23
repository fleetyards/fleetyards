export const uniq = (value: unknown, index: number, self: unknown[]) =>
  self.indexOf(value) === index;

export const uniqByField =
  (field: string) =>
  (
    value: Record<string, unknown>,
    index: number,
    self: Record<string, unknown>[],
  ) =>
    self.findIndex((item) => item[field] === value[field]) === index;

export const sum = (list: number[]) =>
  list.reduce((accumulator, currentValue) => accumulator + currentValue, 0);

export const groupBy = (
  list: Record<string, string | number>[],
  key: string,
) => {
  return list.reduce(
    (result, item) => {
      const group = item[key];
      result[group] = [...result[group]];
      result[group].push(item);
      return result;
    },
    {} as Record<string, Record<string, string | number>[]>,
  );
};

export const sortBy = <T>(list: T[], key: string, decending = false) => {
  return JSON.parse(JSON.stringify(list)).sort(
    (a: Record<string, T>, b: Record<string, T>) => {
      if (decending) {
        if (a[key] < b[key]) {
          return 1;
        }
        if (a[key] > b[key]) {
          return -1;
        }
      } else {
        if (a[key] < b[key]) {
          return -1;
        }
        if (a[key] > b[key]) {
          return 1;
        }
      }
      return 0;
    },
  );
};
