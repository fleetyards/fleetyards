export const uniq = (value, index, self) => {
  return self.indexOf(value) === index
}

export const sum = list => {
  return list.reduce((accumulator, currentValue) => {
    return accumulator + currentValue
  }, 0)
}
