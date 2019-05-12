import { createLocalVue as getLocalVue } from '@vue/test-utils'

export default function createLocalVue(_localVueConfig = { skip: {} }) {
  return getLocalVue()
}
