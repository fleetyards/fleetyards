import Vue from 'vue'
import Router from 'vue-router'
import qs from 'qs'
import Store from 'frontend/lib/Store'
import { routes as initialRoutes } from 'frontend/routes'

Vue.use(Router)

const addTrailingSlashToAllRoutes = (routes) => [].concat(...routes.map((route) => {
  if (['*', '/'].includes(route.path)) {
    return [route]
  }

  const { pathToRegexpOptions = {} } = route

  const path = route.path.replace(/\/$/, '')

  const modifiedRoute = {
    ...route,
    pathToRegexpOptions: {
      ...pathToRegexpOptions,
      strict: true,
    },
    path: `${path}/`,
  }

  if (route.children && route.children.length > 0) {
    modifiedRoute.children = addTrailingSlashToAllRoutes(route.children)
  }

  return [
    modifiedRoute,
    {
      path,
      redirect: (to) => ({
        name: route.name,
        params: to.params || null,
        query: to.query || null,
      }),
    },
  ]
}))

const router = new Router({
  mode: 'history',
  linkActiveClass: 'active',
  linkExactActiveClass: 'active-exact',

  scrollBehavior: (to, _from, savedPosition) => new Promise((resolve) => {
    setTimeout(() => {
      if (to.hash) {
        resolve(false)
      } else if (savedPosition) {
        resolve(savedPosition)
      } else {
        resolve({ x: 0, y: 0 })
      }
    }, 600)
  }),

  parseQuery(query) {
    return qs.parse(query)
  },

  stringifyQuery(query) {
    const result = qs.stringify(query, { arrayFormat: 'brackets' })
    return result ? (`?${result}`) : ''
  },

  routes: addTrailingSlashToAllRoutes(initialRoutes),
})

const validateAndResolveNewRoute = (to) => {
  if (to.meta.needsAuthentication && !Store.getters['session/isAuthenticated']) {
    return {
      routeName: 'login',
      routeParams: {
        redirectToRoute: to.name,
      },
    }
  }
  return null
}

router.beforeResolve((to, _from, next) => {
  const newRoute = validateAndResolveNewRoute(to)
  if (newRoute) {
    router.push({ name: newRoute.routeName, params: newRoute.routeParams }).catch(() => {
      window.location.reload()
    })
  } else {
    next()
  }
})

router.beforeEach((to, from, next) => {
  const newLocale = navigator.language
  if (!Store.state.locale || Store.state.locale !== newLocale) {
    Store.commit('setLocale', newLocale)
  }

  // check if update is available
  if (Store.getters['app/isUpdateAvailable']
    && Object.keys(to.query).length === 0 && to.query.constructor === Object
    && Object.keys(to.params).length === 0 && to.params.constructor === Object) {
    window.location.href = to.path
    return
  }

  next()
})

export default router
