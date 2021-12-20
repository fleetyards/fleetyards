import modelsCollection from 'frontend/api/collections/Models'

import { Route, NavigationGuardNext } from 'vue-router'

export const modelRouteGuard = async function modelRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext
) {
  const model = await modelsCollection.findBySlug(to.params.slug)

  if (!model) {
    next({ name: '404' })
  } else {
    next()
  }
}

export default modelRouteGuard
