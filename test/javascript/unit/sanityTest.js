import { mount } from '@vue/test-utils'
import optionsDefault from './mountDefault'

export default (component, propsData = {}, mocks = {}) => {
  describe(`Component: ${component.name}`, () => {
    let wrapper

    beforeEach(() => {
      wrapper = mount(component, {
        ...optionsDefault(),
        propsData,
        mocks,
      })
    })

    afterEach(() => {
      wrapper.destroy()
    })

    it('should mount', () => {
      expect(wrapper.exists()).toBe(true)
    })
  })
}
