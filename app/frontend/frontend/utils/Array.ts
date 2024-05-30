export const uniq = (value: any, index: number, self: any[]) =>
  self.indexOf(value) === index;

export const uniqByField =
  (field: any) => (value: any, index: number, self: any[]) =>
    self.findIndex((item) => item[field] === value[field]) === index;

export const sum = (list: any[]) =>
  list.reduce((accumulator, currentValue) => accumulator + currentValue, 0);
