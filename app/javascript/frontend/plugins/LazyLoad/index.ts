import Vue from 'vue'
import VueLazyload from 'vue-lazyload'

Vue.use(VueLazyload, {
  attempt: 6,
  preLoad: 2,
  silent: false,
})
