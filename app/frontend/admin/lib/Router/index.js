import Vue from 'vue'
import Router from 'vue-router'
import qs from 'qs'
import { routes } from '@/admin/routes'

Vue.use(Router)

const router = new Router({
  base: window.ON_SUBDOMAIN ? '/admin' : '/',
  linkActiveClass: 'active',
  linkExactActiveClass: 'active',
  mode: 'history',
  parseQuery(query) {
    return qs.parse(query)
  },
  routes,
  scrollBehavior: (to, _from, savedPosition) =>
    new Promise((resolve) => {
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
  stringifyQuery(query) {
    const result = qs.stringify(query)
    return result ? `?${result}` : ''
  },
})

export default router
