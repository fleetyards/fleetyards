import userCollection from 'frontend/api/collections/User'
import { Route, NavigationGuardNext } from 'vue-router'

export const enabledRouteGuard = async function fleetRouteGuard(
  _to: Route,
  _from: Route,
  next: NavigationGuardNext,
) {
  const response = await userCollection.current()

  if (!response.data?.twoFactorRequired) {
    next({ name: 'settings-security-status' })
  } else {
    next()
  }
}

export const disabledRouteGuard = async function publicFleetRouteGuard(
  _to: Route,
  _from: Route,
  next: NavigationGuardNext,
) {
  const response = await userCollection.current()

  if (response.data?.twoFactorRequired) {
    next({ name: 'settings-security-status' })
  } else {
    next()
  }
}
