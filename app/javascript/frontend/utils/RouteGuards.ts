import fleetsCollection from 'frontend/collections/Fleets'
import modelsCollection from 'frontend/collections/Models'
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
    next(vm => {
      // @ts-ignore
      // eslint-disable-next-line no-param-reassign
      vm.fleet = fleet
    })
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
    next(vm => {
      // @ts-ignore
      // eslint-disable-next-line no-param-reassign
      vm.fleet = fleet
    })
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
    next(vm => {
      // @ts-ignore
      // eslint-disable-next-line no-param-reassign
      vm.model = model
    })
  }
}
