import stationsCollection from 'frontend/api/collections/Stations'

import { Route, NavigationGuardNext } from 'vue-router'

export const stationRouteGuard = async function stationRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext,
) {
  const station = await stationsCollection.findBySlug(to.params.slug)

  if (!station) {
    next({ name: '404' })
  } else {
    next()
  }
}

export default stationRouteGuard
