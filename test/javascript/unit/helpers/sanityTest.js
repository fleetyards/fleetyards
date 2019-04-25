import { mount } from '@vue/test-utils'
import defaultComponent from '../__mocks__/defaultComponent'
import optionsDefault from './mountDefault'

/**
 * @description This should check if the component can be rendered
 *
 * @param {object} Component - needs to be a vue component
 * @param {object} options - options for the mounting default are the options from mountDefault.js
 * @param {function} mountDefault - set the mount type default is "mount"
 * @param {object} additionalPlugins - set the additions plugins
 */
export default (
  Component,
  propsData = {},
  additionalPlugins = [],
) => {
  let componentUsed
  if (Component.functional) {
    defaultComponent.components = {
      [Component.name]: Component,
    }
    componentUsed = defaultComponent
  } else {
    componentUsed = Component
  }

  describe(`Component: ${Component.name}`, () => {
    let wrapper

    beforeEach(() => {
      wrapper = mount(componentUsed, {
        ...optionsDefault(),
        propsData,
      }, additionalPlugins)
    })

    afterEach(() => {
      wrapper.destroy()
    })

    it('should mount', () => {
      expect(wrapper.isVueInstance()).toBe(true)
    })
  })
}
