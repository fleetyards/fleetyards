import modelsCollection from '@/frontend/api/collections/Models'

export const modelRouteGuard = async function modelRouteGuard(to, _from, next) {
  const model = await modelsCollection.findBySlug(to.params.slug)

  if (!model) {
    next({ name: '404' })
  } else {
    next()
  }
}

export default modelRouteGuard
