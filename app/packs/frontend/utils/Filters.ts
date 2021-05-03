export function getFilters(formData: Object) {
  const filters = JSON.parse(JSON.stringify(formData))

  Object.keys(filters)
    .filter(key => !filters[key] || filters[key].length === 0)
    .forEach(key => delete filters[key])

  return filters
}

export function isFilterSelected(routeFilters: Object) {
  const filters = JSON.parse(JSON.stringify(routeFilters || {}))

  Object.keys(filters)
    .filter(key => !filters[key] || filters[key].length === 0)
    .forEach(key => delete filters[key])

  return Object.keys(filters).length > 0
}
