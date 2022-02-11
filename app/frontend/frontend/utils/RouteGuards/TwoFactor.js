import userCollection from '@/frontend/api/collections/User'

export const enabledRouteGuard = async function fleetRouteGuard(
  _to,
  _from,
  next
) {
  const response = await userCollection.current()

  if (!response.data?.twoFactorRequired) {
    next({ name: 'settings-security-status' })
  } else {
    next()
  }
}

export const disabledRouteGuard = async function publicFleetRouteGuard(
  _to,
  _from,
  next
) {
  const response = await userCollection.current()

  if (response.data?.twoFactorRequired) {
    next({ name: 'settings-security-status' })
  } else {
    next()
  }
}
