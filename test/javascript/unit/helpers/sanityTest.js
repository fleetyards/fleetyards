import { mount } from '@vue/test-utils'
import defaultComponent from '../__mocks__/defaultComponent'
import optionsDefault from './mountDefault'

// eslint-disable-next-line jest/no-export
export default (
  Component,
  propsData = {},
  mocks = {},
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

  // eslint-disable-next-line jest/valid-describe
  describe(`Component: ${Component.name}`, () => {
    let wrapper

    beforeEach(() => {
      wrapper = mount(componentUsed, {
        ...optionsDefault(),
        propsData,
        mocks,
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
