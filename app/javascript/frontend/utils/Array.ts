export const uniq = (value, index, self) => self.indexOf(value) === index

export const sum = list =>
  list.reduce((accumulator, currentValue) => accumulator + currentValue, 0)
