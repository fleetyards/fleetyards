import userCollection from 'frontend/api/collections/User'
import { Route, NavigationGuardNext } from 'vue-router'

export const enabledRouteGuard = async function fleetRouteGuard(
  _to: Route,
  _from: Route,
  next: NavigationGuardNext,
) {
  const currentUser = await userCollection.current()

  if (!currentUser?.twoFactorRequired) {
    next({ name: 'settings-two-factor' })
  } else {
    next()
  }
}

export const disabledRouteGuard = async function publicFleetRouteGuard(
  _to: Route,
  _from: Route,
  next: NavigationGuardNext,
) {
  const currentUser = await userCollection.current()

  if (currentUser?.twoFactorRequired) {
    next({ name: 'settings-two-factor' })
  } else {
    next()
  }
}
