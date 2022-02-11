import publicUserCollection from '@/frontend/api/collections/PublicUser'

export const publicHangarRouteGuard = async function publicHangarRouteGuard(
  to,
  _from,
  next
) {
  const user = await publicUserCollection.findByUsername(to.params.username)

  if (!user) {
    next({ name: '404' })
  } else {
    next()
  }
}

export default publicHangarRouteGuard
