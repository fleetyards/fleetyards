// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const groupBy = function groupBy(list: any[], key: any) {
  return list.reduce((rv, x) => {
    const value = JSON.parse(JSON.stringify(rv));

    value[x[key]] = rv[x[key]] || [];
    value[x[key]].push(x);

    return value;
  }, {});
};

export const sortBy = function sortBy(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  list: any[],
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  key: any,
  decending = false,
) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return JSON.parse(JSON.stringify(list)).sort((a: any, b: any) => {
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
  });
};
