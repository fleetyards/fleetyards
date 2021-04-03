import fleetsCollection from 'frontend/api/collections/Fleets'
import modelsCollection from 'frontend/api/collections/Models'
import stationsCollection from 'frontend/api/collections/Stations'
import shopsCollection from 'frontend/api/collections/Shops'

import { Route, NavigationGuardNext } from 'vue-router'

export const fleetRouteGuard = async function fleetRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext,
) {
  const fleet = await fleetsCollection.findBySlug(to.params.slug)

  if (!fleet || !fleet.myFleet) {
    next({ name: '404' })
  } else {
    next()
  }
}

export const publicFleetRouteGuard = async function publicFleetRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext,
) {
  const fleet = await fleetsCollection.findBySlug(to.params.slug)

  if (!fleet) {
    next({ name: '404' })
  } else {
    next()
  }
}

export const publicFleetShipsRouteGuard = async function publicFleetShipsRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext,
) {
  const fleet = await fleetsCollection.findBySlug(to.params.slug)

  if (!fleet || (!fleet.publicFleet && !fleet.myFleet)) {
    next({ name: '404' })
  } else {
    next()
  }
}

export const modelRouteGuard = async function modelRouteGuard(
  to: Route,
  _from: Route,
  next: NavigationGuardNext,
) {
  const model = await modelsCollection.findBySlug(to.params.slug)

  if (!model) {
    next({ name: '404' })
  } else {
    next()
  }
}

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
