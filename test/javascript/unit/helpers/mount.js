import { shallowMount } from '@vue/test-utils'
import optionsDefault from './mountDefault'

export default (Component, propsData = {}) => shallowMount(Component, {
  ...optionsDefault(),
  propsData,
})
