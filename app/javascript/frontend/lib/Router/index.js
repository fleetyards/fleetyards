import Vue from 'vue'
import Router from 'vue-router'
import qs from 'qs'
import Store from 'frontend/lib/Store'
import { routes } from 'frontend/routes'

Vue.use(Router)

const router = new Router({
  mode: 'history',
  linkActiveClass: 'active',
  linkExactActiveClass: 'active',
  scrollBehavior (to, from, savedPosition) {
    return new Promise((resolve, _reject) => {
      setTimeout(() => {
        if (savedPosition) {
          resolve(savedPosition)
        } else if (to.hash) {
          resolve({
            selector: `[id='${to.hash.slice(1)}']`,
            offset: { x: 0, y: -20 },
          })
        }
        resolve({ x: 0, y: 0 })
      }, 1000)
    })
  },
  parseQuery(query) {
    return qs.parse(query)
  },
  stringifyQuery(query) {
    const result = qs.stringify(query)
    return result ? (`?${result}`) : ''
  },
  routes,
})

const validateAndResolveNewRoute = (to) => {
  if (to.meta.needsAuthentication && !Store.getters.isAuthenticated) {
    return {
      routeName: 'login',
      routeParams: {
        redirectToRoute: to.name,
      },
    }
  }
  return null
}

router.beforeResolve((to, from, next) => {
  const newRoute = validateAndResolveNewRoute(to)
  if (newRoute) {
    router.push({ name: newRoute.routeName, params: newRoute.routeParams })
  } else {
    next()
  }
})

router.beforeEach((to, from, next) => {
  const newLocale = navigator.language
  if (!Store.state.locale || Store.state.locale !== newLocale) {
    Store.commit('setLocale', newLocale)
  }

  next()
})

router.afterEach((to, from) => {
  if (from.name) {
    Store.commit('setPreviousRoute', {
      name: from.name,
      params: from.params,
      query: from.query,
      hash: from.hash,
    })

    Store.commit('setLastRoute', {
      name: to.name,
      params: to.params,
      query: to.query,
      hash: to.hash,
    })
  }
})

export default router
