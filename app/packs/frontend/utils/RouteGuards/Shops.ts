import shopsCollection from 'frontend/api/collections/Shops'

import { Route, NavigationGuardNext } from 'vue-router'

export const shopRouteGuard = async function shopRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext,
) {
  const shop = await shopsCollection.findBySlugAndStation(to.params)

  if (!shop) {
    next({ name: '404' })
  } else {
    next()
  }
}

export default shopRouteGuard
