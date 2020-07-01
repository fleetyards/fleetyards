import Vue from 'vue'
import Router from 'vue-router'
import qs from 'qs'
import { routes } from 'admin/routes'

Vue.use(Router)

const router = new Router({
  mode: 'history',
  base: window.ON_SUBDOMAIN ? '/admin' : '/',
  linkActiveClass: 'active',
  linkExactActiveClass: 'active',
  scrollBehavior: (to, _from, savedPosition) =>
    new Promise(resolve => {
      setTimeout(() => {
        if (to.hash) {
          resolve()
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
    const result = qs.stringify(query)
    return result ? `?${result}` : ''
  },
  routes,
})

export default router
