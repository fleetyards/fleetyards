import fleetsCollection from '@/frontend/api/collections/Fleets'

export const fleetRouteGuard = async function fleetRouteGuard(to, _from, next) {
  const fleet = await fleetsCollection.findBySlug(to.params.slug)

  if (!fleet || !fleet.myFleet) {
    next({ name: '404' })
  } else {
    next()
  }
}

export const publicFleetRouteGuard = async function publicFleetRouteGuard(
  to,
  _from,
  next
) {
  const fleet = await fleetsCollection.findBySlug(to.params.slug)

  if (!fleet) {
    next({ name: '404' })
  } else {
    next()
  }
}

export const publicFleetShipsRouteGuard =
  async function publicFleetShipsRouteGuard(to, _from, next) {
    const fleet = await fleetsCollection.findBySlug(to.params.slug)

    if (!fleet || (!fleet.publicFleet && !fleet.myFleet)) {
      next({ name: '404' })
    } else {
      next()
    }
  }
