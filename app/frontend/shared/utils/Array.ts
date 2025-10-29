export const uniq = (value: unknown, index: number, self: unknown[]) =>
  self.indexOf(value) === index;

export const uniqByField =
  <T>(field: keyof T) =>
  (value: T, index: number, self: T[]) =>
    self.findIndex((item) => item[field] === value[field]) === index;

export const sum = (list: number[]) =>
  list.reduce((accumulator, currentValue) => accumulator + currentValue, 0);

export const groupBy = <T>(list: T[], key: keyof T) => {
  return list.reduce(
    (result, item) => {
      const group = item[key] as string;
      result[group] = [...(result[group] || [])];
      result[group].push(item);
      return result;
    },
    {} as Record<string, T[]>,
  );
};

export const sortBy = <T>(list: T[], key: string, decending = false): T[] => {
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
