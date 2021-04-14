import ahoy from 'ahoy.js'

ahoy.configure({
  cookies: false,
})

export default {
  install(Vue) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$ahoy = ahoy
  },
}
