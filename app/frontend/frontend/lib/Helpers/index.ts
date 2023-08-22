export const groupBy = function groupBy(list: any[], key: any) {
  return list.reduce((rv, x) => {
    const value = JSON.parse(JSON.stringify(rv));

    value[x[key]] = rv[x[key]] || [];
    value[x[key]].push(x);

    return value;
  }, {});
};

export const sortBy = function sortBy(
  list: any[],
  key: any,
  decending = false,
) {
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
