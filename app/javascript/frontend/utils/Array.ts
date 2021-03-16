export const uniq = (value, index, self) => self.indexOf(value) === index

export const uniqByField = field => (value, index, self) =>
  self.findIndex(item => item[field] === value[field]) === index

export const sum = list =>
  list.reduce((accumulator, currentValue) => accumulator + currentValue, 0)
