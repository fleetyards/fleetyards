import Vue from 'vue'
import { config, RouterLinkStub } from '@vue/test-utils'

config.stubs['router-link'] = RouterLinkStub

Vue.config.productionTip = false

// mock all vue-i18n $t('key') function calls to return the key itself
config.mocks.$t = key => key

jest.mock('frontend/lib/Store/plugins')

// do not swallow errors
console.error = (e, ...args) => {
  // eslint-disable-next-line no-console
  console.debug(e, ...args)
  throw new Error(e)
}

process.on('unhandledRejection', (reason, promise) => {
  console.warn(`Unhandled Rejection at: ${promise}, reason: ${reason.message}, stack: ${reason.stack}`)
})
