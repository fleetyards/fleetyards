import { Location } from 'vue-router'

type QueryParams = {
  sorts: string[]
}

type Dictionary<T> = { [key: string]: T }

interface FleetYardsRouteQuery extends Dictionary<any> {
  q: QueryParams | null
}

interface FleetYardsLocation extends Location {
  query?: FleetYardsRouteQuery
}

export const sortByToggle = function sortByToggle(
  currentRoute: FleetYardsLocation,
  field: string,
  direction: string = 'asc'
) {
  const currentSort = (currentRoute.query?.q || {}).sorts

  const oppositeDirection = ['asc', 'desc'].find((item) => item !== direction)

  if (!oppositeDirection) {
    throw Error(
      'Invalid Direction provided! Direction can only be one of asc|desc'
    )
  }

  const sorts: string[] = []
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

export const sortBy = function sortBy(
  currentRoute: FleetYardsLocation,
  field: string,
  direction: string = 'asc'
) {
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
