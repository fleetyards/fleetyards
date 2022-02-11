import shopsCollection from '@/frontend/api/collections/Shops'

export const shopRouteGuard = async function shopRouteGuard(to, _from, next) {
  const shop = await shopsCollection.findBySlugAndStation(to.params)

  if (!shop) {
    next({ name: '404' })
  } else {
    next()
  }
}

export default shopRouteGuard
