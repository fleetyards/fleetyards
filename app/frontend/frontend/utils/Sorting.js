export const sortByToggle = function sortByToggle(
  currentRoute,
  field,
  direction = 'asc'
) {
  const currentSort = (currentRoute.query?.q || {}).sorts

  const oppositeDirection = ['asc', 'desc'].find((item) => item !== direction)

  if (!oppositeDirection) {
    throw Error(
      'Invalid Direction provided! Direction can only be one of asc|desc'
    )
  }

  const sorts = []
  if (Array.isArray(currentSort)) {
    if (currentSort.includes(`${field} ${direction}`)) {
      sorts.push(`${field} ${oppositeDirection}`)
    } else if (
      currentSort.includes(`${field} ${oppositeDirection}`) ||
      (!currentSort.includes(`${field} asc`) &&
        !currentSort.includes(`${field} desc`))
    ) {
      sorts.push(`${field} ${direction}`)
    }
  } else {
    sorts.push(`${field} ${direction}`)
  }

  return {
    name: currentRoute.name,
    params: currentRoute.params,
    query: {
      ...currentRoute.query,
      q: {
        ...currentRoute.query?.q,
        sorts,
      },
    },
  }
}

export const sortBy = function sortBy(currentRoute, field, direction = 'asc') {
  return {
    name: currentRoute.name,
    params: currentRoute.params,
    query: {
      ...currentRoute.query,
      q: {
        ...currentRoute.query?.q,
        sorts: [`${field} ${direction}`],
      },
    },
  }
}
