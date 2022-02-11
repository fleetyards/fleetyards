import stationsCollection from '@/frontend/api/collections/Stations'

export const stationRouteGuard = async function stationRouteGuard(
  to,
  _from,
  next
) {
  const station = await stationsCollection.findBySlug(to.params.slug)

  if (!station) {
    next({ name: '404' })
  } else {
    next()
  }
}

export default stationRouteGuard
