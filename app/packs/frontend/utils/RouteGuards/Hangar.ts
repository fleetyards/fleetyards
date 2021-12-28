import publicUserCollection from 'frontend/api/collections/PublicUser'

import { Route, NavigationGuardNext } from 'vue-router'

export const publicHangarRouteGuard = async function publicHangarRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext
) {
  const user = await publicUserCollection.findByUsername(to.params.username)

  if (!user) {
    next({ name: '404' })
  } else {
    next()
  }
}

export default publicHangarRouteGuard
